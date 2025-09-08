import streamlit as st
import pandas as pd
from datetime import datetime
import numpy as np 
from styles import render_sidebar_logo
from db_utils import registrar_cambio, get_conn

# =======================================================
# Lógica de la interfaz de usuario
# =======================================================
def show_user_panel2(username, authenticator):
    """Muestra la interfaz de usuario para buscar y registrar reemplazos."""
    
    # Inicializar el estado de la sesión si es la primera vez
    if "reemplazos_descartados" not in st.session_state:
        st.session_state.reemplazos_descartados = []
    if "resultado_busqueda" not in st.session_state:
        st.session_state.resultado_busqueda = None

    with st.sidebar:
        render_sidebar_logo()
        authenticator.logout("🚪 Cerrar sesión", "sidebar")

    st.title("📝 Panel de Usuario")
    st.info(f"Bienvenido {username}, aquí puedes reportar reemplazos.")

    # === Cargar tablas desde la BD ===
    muestra, marco, reemplazos = load_tables_from_db()
    if muestra.empty and marco.empty:
        st.error("⚠ No se encontraron tablas cargadas. Contacte al administrador.")
        return

    # === Interfaz de búsqueda ===
    planilla_input = st.text_input("Ingrese la PLANILLA a reemplazar")

    col1, col2 = st.columns(2)

    with col1:
        if st.button("🔎 Buscar reemplazo"):
            if not planilla_input.strip():
                st.warning("Debe ingresar un número de planilla.")
            else:
                st.session_state.reemplazos_descartados = []
                st.session_state.resultado_busqueda = buscar_y_sugerir_reemplazo(
                    planilla_input, muestra, marco, reemplazos, st.session_state.reemplazos_descartados
                )

    with col2:
        if st.button("🚫 Descartar y obtener otro"):
            if st.session_state.resultado_busqueda and st.session_state.resultado_busqueda["reemplazo_sugerido"]:
                # Agregar el reemplazo actual a la lista de descartados
                st.session_state.reemplazos_descartados.append(st.session_state.resultado_busqueda["reemplazo_sugerido"])
                
                # Buscar un nuevo reemplazo excluyendo los descartados
                st.session_state.resultado_busqueda = buscar_y_sugerir_reemplazo(
                    planilla_input, muestra, marco, reemplazos, st.session_state.reemplazos_descartados
                )
                
                if st.session_state.resultado_busqueda is None or not st.session_state.resultado_busqueda["reemplazo_sugerido"]:
                    st.warning("No se encontraron más reemplazos disponibles para la planilla.")
            else:
                st.warning("No hay un reemplazo sugerido para descartar.")

    # === Mostrar resultado y opciones ===
    if st.session_state.resultado_busqueda:
        resultado = st.session_state.resultado_busqueda
        
        # Ocultar la tabla de reemplazo si no se encontró ninguno
        if resultado["reemplazo_sugerido"]:
            df_view = pd.DataFrame([{
                "PLANILLA ORIGINAL": resultado["planilla_original"],
                "UPM": resultado.get("upm"),
                "MUNICIPIO": resultado.get("municipio_original"),
                "REEMPLAZO PROPUESTO": resultado.get("reemplazo_sugerido"),
                "TIPO": "Probabilístico" if resultado.get("probabilistica") else "Marco"
            }])
            st.markdown("### ✨ Reemplazo Sugerido:")
            st.table(df_view)
            
            # Formulario para confirmar
            motivo = st.text_area("✍ Motivo del reemplazo")
            if st.button("✅ Confirmar y registrar"):
                registrar_cambio(
                    nombre_completo=username,
                    upm_original=resultado["planilla_original"],
                    upm_reemplazo=resultado.get("reemplazo_sugerido", ""),
                    de_acuerdo="Sí",
                    motivo=motivo
                )
                st.success("Reemplazo registrado correctamente.")
                st.caption(f"Guardado el {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                st.session_state.reemplazos_descartados = []
                st.session_state.resultado_busqueda = None
                
        else:
            st.error("No se encontró un reemplazo disponible para la planilla.")


def show_user_panel(username, authenticator):
    """Muestra la interfaz de usuario para buscar y registrar reemplazos."""

    # === Inicializar el estado de la sesión ===
    # Esto evita el 'AttributeError' en el primer arranque
    if "reemplazos_descartados" not in st.session_state:
        st.session_state.reemplazos_descartados = []

    if "resultado_busqueda" not in st.session_state:
        st.session_state.resultado_busqueda = None

    with st.sidebar:
        render_sidebar_logo()
        authenticator.logout("🚪 Cerrar sesión", "sidebar")

    st.title("📝 Panel de Usuario")
    st.info(f"Bienvenido {username}, aquí puedes reportar reemplazos.")

    # === Cargar tablas desde la BD ===
    muestra, marco, reemplazos = load_tables_from_db()
    if muestra.empty or marco.empty:
        st.error("⚠ No se encontraron tablas cargadas. Contacte al administrador.")
        return

    # === Interfaz de búsqueda ===
    planilla_input = st.text_input("Ingrese la PLANILLA a reemplazar")

    col1, col2 = st.columns(2)

    with col1:
        if st.button("🔎 Buscar reemplazo"):
            if not planilla_input.strip():
                st.warning("Debe ingresar un número de planilla.")
            else:
                # Reiniciar descartes en una nueva búsqueda
                st.session_state.reemplazos_descartados = []
                st.session_state.resultado_busqueda = buscar_y_sugerir_reemplazo(
                    planilla_input, muestra, marco, reemplazos, st.session_state.reemplazos_descartados
                )

    with col2:
        if st.button("🚫 Descartar y obtener otro"):
            if st.session_state.resultado_busqueda and st.session_state.resultado_busqueda.get("reemplazo_sugerido"):
                # Agregar el reemplazo actual a la lista de descartados
                st.session_state.reemplazos_descartados.append(st.session_state.resultado_busqueda["reemplazo_sugerido"])

                # Buscar un nuevo reemplazo excluyendo los descartados
                st.session_state.resultado_busqueda = buscar_y_sugerir_reemplazo(
                    planilla_input, muestra, marco, reemplazos, st.session_state.reemplazos_descartados
                )

                if st.session_state.resultado_busqueda is None or not st.session_state.resultado_busqueda.get("reemplazo_sugerido"):
                    st.warning("No se encontraron más reemplazos disponibles para la planilla.")
            else:
                st.warning("No hay un reemplazo sugerido para descartar.")

    # === Mostrar resultado y opciones ===
    if st.session_state.resultado_busqueda:
        resultado = st.session_state.resultado_busqueda

        if resultado.get("reemplazo_sugerido"):
            # Obtener la información completa de la planilla original y el reemplazo desde el marco
            fila_original = marco[marco["PLANILLA"] == resultado["planilla_original"]].iloc[0]
            reemplazo_sugerido = resultado["reemplazo_sugerido"]
            fila_rep = marco[marco["PLANILLA"] == str(reemplazo_sugerido)].iloc[0]

            df_view = pd.DataFrame([{
                "PLANILLA ORIGINAL": resultado["planilla_original"],
                "UPM ORIGINAL": fila_original.get("UPM"),
                "MUNICIPIO ORIGINAL": fila_original.get("MUNICIPIO_DESTINO_RUTA"),
                "---": "---",
                "PLANILLA DE REEMPLAZO": reemplazo_sugerido,
                "UPM DE REEMPLAZO": fila_rep.get("UPM"),
                "MUNICIPIO DE REEMPLAZO": fila_rep.get("MUNICIPIO_DESTINO_RUTA"),
                "TIPO DE REEMPLAZO": "Probabilístico" if resultado.get("probabilistica") else "Marco"
            }])

            st.markdown("### ✨ Reemplazo Sugerido:")
            st.table(df_view.T)

            # Formulario para confirmar
            motivo = st.text_area("✍ Motivo del reemplazo")
            if st.button("✅ Confirmar y registrar"):
                registrar_cambio(
                    nombre_completo=username,
                    upm_original=resultado["planilla_original"],
                    upm_reemplazo=resultado.get("reemplazo_sugerido", ""),
                    de_acuerdo="Sí",
                    motivo=motivo
                )
                st.success("Reemplazo registrado correctamente.")
                st.caption(f"Guardado el {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                st.session_state.reemplazos_descartados = []
                st.session_state.resultado_busqueda = None

        else:
            st.error("No se encontró un reemplazo disponible para la planilla.")



# =======================================================
# Funciones auxiliares mejoradas
# =======================================================

def load_tables_from_db():
    """Carga las tablas desde sqlite."""
    conn = get_conn()
    muestra = marco = reemplazos = pd.DataFrame()
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
    return muestra, marco, reemplazos


def buscar_y_sugerir_reemplazo(planilla, muestra, marco, reemplazos, descartados):
    """
    Algoritmo de búsqueda y asignación de reemplazo.
    Considera reemplazos probabilísticos primero y luego por marco.
    Devuelve un reemplazo aleatorio no descartado.
    """
    planilla = str(planilla).strip()

    # Intento 1: Buscar en la tabla de reemplazos probabilísticos
    fila_muestra = muestra[muestra["PLANILLA"] == planilla] if "PLANILLA" in muestra.columns else pd.DataFrame()
    if not fila_muestra.empty:
        upm = fila_muestra.iloc[0].get("UPM")
        
        # Filtrar reemplazos por UPM y excluir los ya descartados
        candidatos_reemp = reemplazos[
            (reemplazos["UPM"] == upm) &
            (~reemplazos["REEMPLAZO"].isin(descartados))
        ]

        if not candidatos_reemp.empty:
            # Seleccionar un reemplazo aleatorio
            reemplazo_sugerido = candidatos_reemp["REEMPLAZO"].sample(n=1).iloc[0]
            fila_rep = marco[marco["PLANILLA"] == str(reemplazo_sugerido)]
            
            if not fila_rep.empty:
                return {
                    "planilla_original": planilla,
                    "upm_original": fila_muestra.iloc[0].get("UPM"),
                    "municipio_original": fila_muestra.iloc[0].get("DESTINO"),
                    "reemplazo_sugerido": reemplazo_sugerido,
                    "probabilistica": True
                }

    # Intento 2: Buscar en la tabla marco
    fila_marco = marco[marco["PLANILLA"] == planilla] if "PLANILLA" in marco.columns else pd.DataFrame()
    if not fila_marco.empty:
        # Asegurarse de que la planilla original no sea ya un reemplazo
        flag = str(fila_marco.iloc[0].get("REEMPLAZO", "")).lower()
        if flag in ("si", "sí", "yes", "true", "1"):
            st.warning(f"La planilla {planilla} ya ha sido marcada como reemplazo en el marco.")
            return None

        # Buscar candidatos en la misma franja horaria y que no sean reemplazos
        hora = fila_marco.iloc[0].get("HORA_DESPACHO")
        municipio = fila_marco.iloc[0].get("MUNICIPIO_DESTINO_RUTA")
        candidatos_marco = marco[
            (marco["HORA_DESPACHO"] == hora) &
            (marco["MUNICIPIO_DESTINO_RUTA"] == municipio) &
            (~marco["REEMPLAZO"].astype(str).str.lower().isin(["si", "sí", "yes", "true", "1"])) &
            (~marco["PLANILLA"].isin(descartados))
        ]

        if not candidatos_marco.empty:
            # Seleccionar un candidato aleatorio
            fila_rep = candidatos_marco.sample(n=1).iloc[0]
            
            return {
                "planilla_original": planilla,
                "upm_original": fila_marco.iloc[0].get("UPM"),
                "municipio_original": fila_marco.iloc[0].get("MUNICIPIO_DESTINO_RUTA"),
                "reemplazo_sugerido": fila_rep.get("PLANILLA"),
                "probabilistica": False
            }

    return None