import streamlit as st
import pandas as pd
from datetime import datetime
import numpy as np
import random
from styles import render_sidebar_logo
from db_utils import registrar_cambio, get_conn

# =======================================================
# Lógica de la interfaz de usuario
# =======================================================
def show_user_panel(username, authenticator):
    """Muestra la interfaz de usuario para buscar y registrar reemplazos."""

    # Inicializar el estado de la sesión si es la primera vez
    if "reemplazos_descartados" not in st.session_state:
        st.session_state.reemplazos_descartados = []
    if "resultado_busqueda" not in st.session_state:
        st.session_state.resultado_busqueda = None
    if "reemplazo_registrado" not in st.session_state:
        st.session_state.reemplazo_registrado = False

    # Limpiar campos específicos si se solicitó
    if st.session_state.get("limpiar_campos", False):
        if "nombre_completo_form" in st.session_state:
            st.session_state["nombre_completo_form"] = ""
        if "planilla_input_form" in st.session_state:
            st.session_state["planilla_input_form"] = ""
        st.session_state.limpiar_campos = False

    with st.sidebar:
        render_sidebar_logo()
        authenticator.logout("🚪 Cerrar sesión", "sidebar")

    st.title("📝 Panel de Usuario")
    st.info(f"Bienvenido, en este espacio podrá gestionar solicitudes de reemplazo de manera rápida y sencilla.")

    # === Cargar tablas desde la BD ===
    muestra, marco, reemplazos, plantilla = load_tables_from_db()
    if muestra.empty and marco.empty:
        st.error("⚠ No se encontraron tablas cargadas. Contacte al administrador.")
        return

    # === Interfaz de búsqueda ===
    st.info("""
    Complete este formulario para solicitar el reemplazo de su planilla actual por una alternativa disponible.  
    El propósito es garantizar la correcta gestión de reemplazos cuando la ruta asignada no pueda cumplirse o presente inconvenientes, asegurando así la continuidad y calidad del servicio de transporte.
    """)

    # === FORMULARIO PRINCIPAL ===
    with st.form("formulario_reemplazo_unique"):
        # 1. Nombre completo (obligatorio)
        nombre_completo = st.text_input(
            "👤 Ingrese su nombre completo *",
            placeholder="Ingrese su nombre completo",
            help="Campo obligatorio",
            key="nombre_completo_form"
        )

        # 2. Planilla a reemplazar (obligatorio)
        planilla_input = st.text_input(
            "📄 Ingrese la PLANILLA a reemplazar *",
            placeholder="Ejemplo: 12345",
            help="Campo obligatorio",
            key="planilla_input_form"
        )

        # 5. Botón para buscar y registrar
        submitted = st.form_submit_button("🔎 Buscar reemplazo y registrar", use_container_width=True)

    # === CAMPOS INTERACTIVOS (FUERA DEL FORMULARIO) ===
    # 3. Justificación (obligatorio)
    st.markdown("**🔍 Justificación del reemplazo ***")
    motivos = [
        "1. Situaciones de orden público",
        "2. Problemas en la vía (bloqueos, derrumbes, inundaciones, etc)",
        "3. La ruta no salió en la hora programada",
        "4. Fallas técnicas",
        "5. Cupo incompleto",
        "6. Sin salida en la hora asignada",
    ]
    
    motivo_seleccionado = st.selectbox(
        "Seleccione el motivo del reemplazo:",
        ["Seleccione una opción..."] + motivos + ["Otros"]
    )
    
    # 4. Justificación personalizada (si selecciona "Otros")
    motivo_personalizado = ""
    if motivo_seleccionado == "Otros":
        motivo_personalizado = st.text_area(
            "✍ Ingrese el motivo personalizado: *",
            placeholder="Describa detalladamente el motivo del reemplazo... (mínimo 80 caracteres)",
            help="Campo obligatorio. Debe tener mínimo 80 caracteres"
        )
        # Mostrar contador de caracteres
        if motivo_personalizado:
            char_count = len(motivo_personalizado)
            if char_count < 80:
                st.warning(f"⚠️ Faltan {80 - char_count} caracteres (actual: {char_count}/80)")
            else:
                st.success(f"✅ Caracteres: {char_count}/80")
    
    # Asignar el motivo final
    if motivo_seleccionado == "Otros":
        motivo_final = motivo_personalizado
    else:
        motivo_final = motivo_seleccionado

    # === VALIDACIONES Y PROCESAMIENTO ===
    if submitted:
        # Validar campos obligatorios
        errores = []
        
        if not nombre_completo.strip():
            errores.append("• Debe ingresar su nombre completo")
        
        if not planilla_input.strip():
            errores.append("• Debe ingresar un número de planilla")
        
        if motivo_seleccionado == "Seleccione una opción...":
            errores.append("• Debe seleccionar un motivo del reemplazo")
        
        if motivo_seleccionado == "Otros" and not motivo_personalizado.strip():
            errores.append("• Debe ingresar un motivo personalizado")
            
        if motivo_seleccionado == "Otros" and len(motivo_personalizado.strip()) < 80:
            errores.append("• El motivo personalizado debe tener mínimo 80 caracteres")

        # Mostrar errores si los hay
        if errores:
            st.error("**Por favor, complete los siguientes campos:**")
            for error in errores:
                st.error(error)
        else:
            # === BUSCAR REEMPLAZO ===
            with st.spinner("🔍 Buscando reemplazo disponible..."):
                resultado_busqueda = buscar_y_sugerir_reemplazo(
                    planilla_input,
                    muestra,
                    marco,
                    reemplazos,
                    plantilla,
                    []
                )

            if resultado_busqueda and len(resultado_busqueda) > 0:
                # Tomar solo el primer reemplazo encontrado
                reemplazo_asignado = resultado_busqueda[0]
                
                # === REGISTRAR EN BASE DE DATOS INMEDIATAMENTE ===
                try:
                    registrar_cambio(
                        usuario=nombre_completo,
                        planilla_original=planilla_input,
                        planilla_reemplazo=reemplazo_asignado.get("PLANILLA"),
                        probabilistica=reemplazo_asignado.get("probabilistica"),
                        upm_reemplazo=reemplazo_asignado.get("UPM"),
                        departamento_reemplazo=reemplazo_asignado.get("DEPTO"),
                        municipio_reemplazo=reemplazo_asignado.get("MUNICIPIO"),
                        hora_reemplazo=str(reemplazo_asignado.get("HORA_DESPACHO", "")),
                        motivo_reemplazo=motivo_final
                    )
                    
                    # === MOSTRAR RESULTADO ===
                    st.success("✅ **¡Reemplazo registrado exitosamente!**")
                    st.info("**Su reemplazo asignado ha sido este:**")
                    
                    # Crear DataFrame para mostrar la información del reemplazo
                    df_reemplazo = pd.DataFrame([{
                        "Planilla": reemplazo_asignado.get("PLANILLA"),
                        "UPM": reemplazo_asignado.get("UPM"),
                        "Departamento": reemplazo_asignado.get("DEPTO"),
                        "Municipio": reemplazo_asignado.get("MUNICIPIO"),
                        "Hora de Despacho": reemplazo_asignado.get("HORA_DESPACHO")
                    }])
                    
                    # Mostrar la tabla con el reemplazo asignado
                    st.dataframe(df_reemplazo, hide_index=True, use_container_width=True)
                    
                    # Información adicional
                    col1, col2 = st.columns(2)
                    with col1:
                        st.caption(f"📅 Registrado el: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                    with col2:
                        st.caption(f"👤 Usuario: {nombre_completo}")
                    
                    # Mostrar detalles del reemplazo
                    with st.expander("📋 Ver detalles del reemplazo"):
                        st.write(f"**Planilla original:** {planilla_input}")
                        st.write(f"**Planilla de reemplazo:** {reemplazo_asignado.get('PLANILLA')}")
                        st.write(f"**Motivo:** {motivo_final}")
                        st.write(f"**Tipo:** {'Probabilístico' if reemplazo_asignado.get('probabilistica') else 'Marco'}")
                    
                    # Limpiar solo nombre y planilla
                    st.session_state.limpiar_campos = True
                        
                except Exception as e:
                    st.error(f"❌ **Error al registrar el reemplazo:** {str(e)}")
                    st.error("Por favor, contacte al administrador del sistema.")
                    
            else:
                # No se encontró reemplazo disponible
                st.error("❌ **No se encontraron reemplazos disponibles**")
                st.info("Posibles causas:")
                st.info("• La planilla ingresada no existe en el sistema")
                st.info("• No hay rutas disponibles para la misma hora")
                st.info("• Todos los reemplazos posibles ya están ocupados")
                st.info("Por favor, contacte al administrador del sistema.")


# =======================================================
# Funciones auxiliares
# =======================================================

def load_tables_from_db():
    """Carga las tablas desde sqlite."""
    conn = get_conn()
    muestra = marco = reemplazos = plantilla = pd.DataFrame()
    try:
        muestra = pd.read_sql("SELECT * FROM muestra", conn)
        muestra.columns = muestra.columns.str.upper()
    except Exception as e:
        st.error(f"Error al cargar la tabla 'muestra': {e}")
    try:
        marco = pd.read_sql("SELECT * FROM marco", conn)
        marco.columns = marco.columns.str.upper()
    except Exception as e:
        st.error(f"Error al cargar la tabla 'marco': {e}")
    try:
        reemplazos = pd.read_sql("SELECT * FROM reemplazo", conn)
        reemplazos.columns = reemplazos.columns.str.upper()
    except Exception as e:
        st.error(f"Error al cargar la tabla 'reemplazo': {e}")
    try:
        plantilla = pd.read_sql("SELECT * FROM plantilla", conn)
        plantilla.columns = plantilla.columns.str.upper()
    except Exception as e:
        st.error(f"Error al cargar la tabla 'plantilla': {e}")
    return muestra, marco, reemplazos, plantilla


def generar_upm(fila):
    """Genera la UPM concatenando FECHA_DESPACHO + HORA_DESPACHO + MUNICIPIO_DESTINO_RUTA."""
    return f"{fila.get('FECHA_DESPACHO','')}{fila.get('HORA_DESPACHO','')}{fila.get('MUNICIPIO_DESTINO_RUTA','')}"


def buscar_y_sugerir_reemplazo(planilla, muestra, marco, reemplazos, plantilla, descartados):
    """
    Algoritmo de búsqueda y asignación de reemplazo ALEATORIO.
    Busca reemplazos para la misma hora y día, diferente destino.
    """
    planilla = str(planilla).strip()
    candidatos = []

    # --- Asegurar que MARCO tenga columna UPM generada ---
    if "UPM" not in marco.columns:
        marco["UPM"] = (
            marco["FECHA_DESPACHO"].astype(str).str.strip() + "_" +
            marco["HORA_DESPACHO"].astype(str).str.strip() + "_" +
            marco["MUNICIPIO_DESTINO_RUTA"].astype(str).str.strip()
        )

    # === Función auxiliar para buscar DEPTO ===
    def obtener_depto(upm, destino):
        depto = None
        # 1. Buscar en PLANTILLA por UPM
        if "UPM" in plantilla.columns and not plantilla.empty:
            fila_plantilla = plantilla[plantilla["UPM"] == str(upm)]
            if not fila_plantilla.empty and "DEPTO" in fila_plantilla.columns:
                depto = fila_plantilla.iloc[0]["DEPTO"]

        # 2. Si no se encontró, hacer CRUCE con MUESTRA por DESTINO
        if (not depto) and "DESTINO" in muestra.columns:
            fila_muestra = muestra[muestra["DESTINO"] == str(destino)]
            if not fila_muestra.empty and "DEPTO" in fila_muestra.columns:
                depto = fila_muestra.iloc[0]["DEPTO"]

        return depto

    # --- Buscar en MARCO por fecha y hora ---
    if "PLANILLA" in marco.columns:
        fila_marco = marco[marco["PLANILLA"] == planilla]
        if not fila_marco.empty:
            flag = str(fila_marco.iloc[0].get("REEMPLAZO", "")).lower()
            if flag in ("si", "sí", "yes", "true", "1"):
                return None  # Ya es un reemplazo

            # Obtener fecha y hora de la planilla original
            fecha_original = fila_marco.iloc[0].get("FECHA_DESPACHO")
            hora_original = fila_marco.iloc[0].get("HORA_DESPACHO")
            destino_original = fila_marco.iloc[0].get("DESTINO")
            
            # Buscar candidatos con misma fecha y hora, diferente destino
            candidatos_marco = marco[
                (marco["FECHA_DESPACHO"] == fecha_original) &
                (marco["HORA_DESPACHO"] == hora_original) &
                (marco["DESTINO"] != destino_original) &  # Diferente destino
                (marco["PLANILLA"] != planilla) &  # No la misma planilla
                (~marco["REEMPLAZO"].astype(str).str.lower().isin(["si", "sí", "yes", "true", "1"])) &
                (~marco["PLANILLA"].isin(descartados))
            ]

            if not candidatos_marco.empty:
                # SELECCIÓN ALEATORIA - tomar uno aleatorio
                fila_rep = candidatos_marco.sample(n=1).iloc[0]
                depto = obtener_depto(
                    fila_rep.get("UPM"),
                    fila_rep.get("DESTINO")
                )
                candidatos.append({
                    "PLANILLA": fila_rep.get("PLANILLA"),
                    "UPM": fila_rep.get("UPM"),
                    "DEPTO": depto,
                    "MUNICIPIO": fila_rep.get("DESTINO"),
                    "HORA_DESPACHO": fila_rep.get("HORA_DESPACHO"),
                    "probabilistica": False
                })
                return candidatos

    return None
