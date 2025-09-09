import streamlit as st
import pandas as pd
from datetime import datetime
import numpy as np
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
    if "motivo_reemplazo" not in st.session_state:
        st.session_state.motivo_reemplazo = ""

    with st.sidebar:
        render_sidebar_logo()
        authenticator.logout("🚪 Cerrar sesión", "sidebar")

    st.title("📝 Panel de Usuario")
    st.info(f"Bienvenido {username}, aquí puedes reportar reemplazos.")

    # === Cargar tablas desde la BD ===
    muestra, marco, reemplazos, plantilla = load_tables_from_db()
    if muestra.empty and marco.empty:
        st.error("⚠ No se encontraron tablas cargadas. Contacte al administrador.")
        return

    # === Interfaz de búsqueda ===
    st.info("""
    Como usuario, usted debe completar este formulario para solicitar el cambio de su UPM (Unidad Primaria de Muestreo) actual por una nueva disponible.  
    El objetivo es gestionar de manera eficiente los reemplazos cuando su ruta asignada no esté programada o presente algún inconveniente, 
    asegurando así la continuidad del servicio en la Terminal de Transportes.
    """)

    # Campos en paralelo: Nombre completo y Planilla
    col1, col2 = st.columns([2, 2])
    with col1:
        nombre_completo = st.text_input("👤 Ingrese su nombre completo", value=username)
    with col2:
        planilla_input = st.text_input("📄 Ingrese la PLANILLA a reemplazar")

    if st.button("🔎 Buscar reemplazos"):
        if not planilla_input.strip():
            st.warning("Debe ingresar un número de planilla.")
        else:
            st.session_state.reemplazos_descartados = []
            st.session_state.resultado_busqueda = buscar_y_sugerir_reemplazo(
                planilla_input,
                muestra,
                marco,
                reemplazos,
                plantilla,
                st.session_state.reemplazos_descartados
            )

    # === Mostrar resultado y opciones ===
    if st.session_state.resultado_busqueda:
        resultado = st.session_state.resultado_busqueda

        if isinstance(resultado, list) and resultado:
            st.markdown("### ✨ Reemplazos Sugeridos:")

            # Crear un DataFrame para mostrar todas las opciones
            df_options = pd.DataFrame([
                {
                    "Planilla": row.get("PLANILLA"),
                    "UPM": row.get("UPM"),
                    "Departamento": row.get("DEPTO"),
                    "Municipio": row.get("MUNICIPIO")
                } for row in resultado
            ])
            
            # Mostrar la tabla de opciones
            st.dataframe(df_options, hide_index=True)

            # Selector de reemplazo
            opciones_radio = df_options["Planilla"].tolist()
            reemplazo_elegido = st.radio(
                "Seleccione el reemplazo que desea realizar:",
                opciones_radio
            )
            
            # Formulario para confirmar
            motivos = [
                        "1. Situaciones de orden público",
                        "2. Problemas en la vía (bloqueos, derrumbes, inundaciones, etc)",
                        "3. La ruta no salió en la hora programada",
                        "4. Fallas técnicas",
                        "5. Cupo imcompleto",
                        "6. Sin salida en la hora asignada",
                    ]
            motivo_seleccionado = st.selectbox("Seleccione el motivo del reemplazo:", [""] + motivos + ["Otros"])
            
            motivo_personalizado = ""
            if motivo_seleccionado == "Otros":
                motivo_personalizado = st.text_area("✍ Ingrese el motivo personalizado:")
            else:
                motivo_personalizado = motivo_seleccionado

            if st.button("✅ Confirmar y registrar"):
                # Encontrar el diccionario del reemplazo elegido para obtener si era probabilístico
                reemplazo_info = next((item for item in resultado if item["PLANILLA"] == reemplazo_elegido), None)
                if reemplazo_info:
                    registrar_cambio(
                        nombre_completo=username,
                        upm_original=planilla_input,
                        upm_reemplazo=reemplazo_elegido,
                        motivo=motivo_personalizado,
                        probabilistica=reemplazo_info.get("probabilistica")
                    )
                    st.success(f"Reemplazo de la planilla {reemplazo_elegido} registrado correctamente.")
                    st.caption(f"Guardado el {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                    st.session_state.reemplazos_descartados = []
                    st.session_state.resultado_busqueda = None
                else:
                    st.error("Ocurrió un error al registrar el reemplazo. Por favor, intente de nuevo.")
        else:
            st.error("No se encontraron reemplazos disponibles para la planilla.")

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
    Algoritmo de búsqueda y asignación de reemplazo.
    Devuelve hasta 3 opciones disponibles con DEPTO cruzado correctamente:
    1. Primero busca en PLANTILLA por UPM.
    2. Si no lo encuentra, busca en MUESTRA por DESTINO (marco.DESTINO = muestra.DESTINO).
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

    # --- 1. Reemplazos probabilísticos ---
    if "PLANILLA" in muestra.columns:
        fila_muestra = muestra[muestra["PLANILLA"] == planilla]
        if not fila_muestra.empty:
            upm = fila_muestra.iloc[0].get("UPM")
            if "UPM" in reemplazos.columns and "TIPO_REEMPLAZO" in reemplazos.columns:
                candidatos_reemp = reemplazos[
                    (reemplazos["UPM"] == upm) &
                    (reemplazos["TIPO_REEMPLAZO"].str.lower() == "probabilistico") &
                    (~reemplazos["REEMPLAZO"].isin(descartados))
                ]
                if not candidatos_reemp.empty:
                    for _, fila_reemp in candidatos_reemp.iterrows():
                        fila_marco_reemp = marco[marco["PLANILLA"] == str(fila_reemp["REEMPLAZO"])]
                        if not fila_marco_reemp.empty:
                            fila_marco_reemp = fila_marco_reemp.iloc[0]
                            depto = obtener_depto(
                                fila_marco_reemp.get("UPM"),
                                fila_marco_reemp.get("DESTINO")   # 🔹 aquí usamos DESTINO de MARCO
                            )
                            candidatos.append({
                                "PLANILLA": fila_reemp["REEMPLAZO"],
                                "UPM": fila_marco_reemp.get("UPM"),
                                "DEPTO": depto,
                                "MUNICIPIO": fila_marco_reemp.get("DESTINO"),
                                "probabilistica": True
                            })
                    return candidatos[:3]

    # --- 2. Reemplazos desde MARCO ---
    if "PLANILLA" in marco.columns:
        fila_marco = marco[marco["PLANILLA"] == planilla]
        if not fila_marco.empty:
            flag = str(fila_marco.iloc[0].get("REEMPLAZO", "")).lower()
            if flag in ("si", "sí", "yes", "true", "1"):
                st.warning(f"La planilla {planilla} ya ha sido marcada como reemplazo en el marco.")
                return None

            hora = fila_marco.iloc[0].get("HORA_DESPACHO")
            candidatos_marco = marco[
                (marco["HORA_DESPACHO"] == hora) &
                (~marco["REEMPLAZO"].astype(str).str.lower().isin(["si", "sí", "yes", "true", "1"])) &
                (~marco["PLANILLA"].isin(descartados))
            ]

            if not candidatos_marco.empty:
                n_samples = min(3, len(candidatos_marco))
                candidatos_elegidos = candidatos_marco.sample(n=n_samples, replace=False)
                for _, fila_rep in candidatos_elegidos.iterrows():
                    depto = obtener_depto(
                        fila_rep.get("UPM"),
                        fila_rep.get("DESTINO")   # 🔹 aquí también usamos DESTINO de MARCO
                    )
                    candidatos.append({
                        "PLANILLA": fila_rep.get("PLANILLA"),
                        "UPM": fila_rep.get("UPM"),
                        "DEPTO": depto,
                        "MUNICIPIO": fila_rep.get("DESTINO"),
                        "probabilistica": False
                    })
                return candidatos

    return None


def registrar_cambio(nombre_completo, upm_original, upm_reemplazo, motivo, probabilistica):
    """Registra el cambio en la base de datos para monitoreo."""
    conn = get_conn()
    cursor = conn.cursor()
    
    fecha_registro = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    sql = """
    INSERT INTO registro_reemplazos (
        nombre_completo, 
        upm_original, 
        upm_reemplazo, 
        motivo, 
        probabilistica, 
        fecha_registro
    ) VALUES (?, ?, ?, ?, ?, ?)
    """
    
    cursor.execute(sql, (
        nombre_completo, 
        upm_original, 
        upm_reemplazo, 
        motivo, 
        probabilistica, 
        fecha_registro
    ))
    
    conn.commit()
    conn.close()
