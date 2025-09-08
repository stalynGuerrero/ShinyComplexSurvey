import streamlit as st
import pandas as pd
import openpyxl  # Para archivos .xlsx
from db_utils import guardar_bases
from ui_users import show_user_admin  
from styles import load_styles, render_sidebar_logo
from db_utils import guardar_bases, cargar_cambios

def show_admin_panel(username, authenticator):
    """
    Muestra el panel de administración.
    """
    with st.sidebar:
        render_sidebar_logo()
        authenticator.logout("🚪 Cerrar sesión", "sidebar")


    st.title("👨‍💼 Panel de Administración")
    st.info("""
    **Bienvenido, Administrador 👋**
    
    Aquí puedes gestionar las bases de datos y los usuarios:
    - 📂 Cargar Base (Excel con pestañas: reemplazo, marco y muestra)
    - 👥 Gestión de Usuarios
    """)

    # --- Define pestañas ---
    tab1, tab2, tab3 = st.tabs(["📂 Cargar Base", "👥 Gestión de Usuarios", "📊 Monitoreo de Cambios"])

    # === Función auxiliar para mapeo ===
    def map_columns_section(df, expected_cols, df_name):
        st.markdown(f"### 🔧 Mapeo de columnas para **{df_name.upper()}**")
        mapeo = {}
        cols = st.columns(len(expected_cols))
        for i, col in enumerate(expected_cols):
            with cols[i]:
                mapeo[col] = st.selectbox(
                    f"{col}",
                    options=["(ninguna)"] + list(df.columns),
                    key=f"map_{df_name}_{col}"
                )
        st.dataframe(df.head(10), use_container_width=True)
        return mapeo

    # === TAB1: Cargar base ===
    # === TAB1: Cargar base ===
    with tab1:
        archivo_excel = st.file_uploader("📂 Suba el archivo Excel", type=["xlsx"], key="admin_excel")

        if archivo_excel:
            try:
                # --- Paso 1: Selección de hojas si aún no se han cargado ---
                if "df_muestra" not in st.session_state:
                    xls = pd.ExcelFile(archivo_excel)
                    hojas = xls.sheet_names
                    st.success(f"✅ Hojas detectadas: {', '.join(hojas)}")

                    hoja_remplazo = st.selectbox("Seleccione la hoja de REMPLAZO:", hojas, key="hoja_remplazo")
                    hoja_marco = st.selectbox("Seleccione la hoja de MARCO:", hojas, key="hoja_marco")
                    hoja_muestra = st.selectbox("Seleccione la hoja de MUESTRA:", hojas, key="hoja_muestra")

                    if st.button("📥 Cargar pestañas seleccionadas"):
                        # Cargar los DataFrames y guardarlos en el estado de la sesión
                        st.session_state.df_remplazo = pd.read_excel(archivo_excel, sheet_name=hoja_remplazo)
                        st.session_state.df_marco = pd.read_excel(archivo_excel, sheet_name=hoja_marco)
                        st.session_state.df_muestra = pd.read_excel(archivo_excel, sheet_name=hoja_muestra)
                        st.rerun()

                # --- Paso 2: Mapeo y confirmación (si los DFs ya están en la sesión) ---
                else:
                    # Recuperar bases desde sesión
                    df_remplazo = st.session_state.df_remplazo
                    df_marco = st.session_state.df_marco
                    df_muestra = st.session_state.df_muestra

                    # Columnas esperadas
                    columnas_muestra = ["PLANILLA", "UPM", "FECHA", "DESTINO", "DEPTO"]
                    columnas_marco = ["PLANILLA", "reemplazo", "HORA_DESPACHO", "FECHA_DESPACHO",
                                      "MUNICIPIO_DESTINO_RUTA", "DESTINO"]
                    columnas_remplazo = ["PLANILLA", "UPM", "TIPO_REEMPLAZO", "REEMPLAZO"]

                    # Mapear columnas
                    mapeo_muestra = map_columns_section(df_muestra, columnas_muestra, "muestra")
                    mapeo_marco = map_columns_section(df_marco, columnas_marco, "marco")
                    mapeo_remplazo = map_columns_section(df_remplazo, columnas_remplazo, "remplazo")

                    if st.button("✅ Confirmar mapeo y guardar"):
                        # Renombrar columnas
                        df_muestra.rename(columns={v: k for k, v in mapeo_muestra.items() if v != "(ninguna)"}, inplace=True)
                        df_marco.rename(columns={v: k for k, v in mapeo_marco.items() if v != "(ninguna)"}, inplace=True)
                        df_remplazo.rename(columns={v: k for k, v in mapeo_remplazo.items() if v != "(ninguna)"}, inplace=True)

                        # Filtrar columnas según definición
                        df_muestra = df_muestra.reindex(columns=columnas_muestra)
                        df_marco = df_marco.reindex(columns=columnas_marco)
                        df_remplazo = df_remplazo.reindex(columns=columnas_remplazo)

                        # --- Crear base de municipios ---
                        df_muestra["COD_MUNICIPIO"] = df_muestra["UPM"].astype(str).str[-5:]
                        df_municipios = df_muestra[["COD_MUNICIPIO", "DESTINO", "DEPTO"]].drop_duplicates()
                        df_municipios.rename(columns={"DESTINO": "MUNICIPIO", "DEPTO": "DEPARTAMENTO"}, inplace=True)
                        df_municipios.sort_values(["DEPARTAMENTO", "MUNICIPIO"], inplace=True)
                        df_municipios.reset_index(drop=True, inplace=True)

                        # Guardar todas las bases en SQL
                        # NOTA: Asegúrate de que la función 'guardar_bases' en 'db_utils.py'
                        # acepte el argumento df_municipios
                        guardar_bases(df_remplazo, df_marco, df_muestra, df_municipios=df_municipios, var_upm="UPM")
                        st.session_state.df_municipios = df_municipios

                        st.success(f"💾 Tablas principales y base de municipios guardadas en la base de datos ({len(df_municipios)} municipios).")

                        # Reset de session_state y recargar
                        for key in ["df_muestra", "df_marco", "df_remplazo"]:
                            if key in st.session_state:
                                del st.session_state[key]
                        st.rerun()
            
            except Exception as e:
                st.error(f"❌ Error al procesar el archivo: {e}")
                # Limpiar estado de la sesión para permitir un nuevo intento
                for key in ["df_muestra", "df_marco", "df_remplazo"]:
                    if key in st.session_state:
                        del st.session_state[key]
                st.rerun()
    # === TAB2: Gestión de usuarios ===
    with tab2:
        show_user_admin()
    with tab3:
         st.subheader("📊 Cambios registrados por los usuarios")
         df_cambios = cargar_cambios()

         if not df_cambios.empty:
            # Renombrar columnas para el reporte
            df_cambios = df_cambios.rename(columns={
                "nombre_completo": "usuario",
                "fecha": "fecha",
                "planilla": "planilla" if "planilla" in df_cambios.columns else "upm_original",
                "upm_original": "upm",
                "upm_reemplazo": "reemplazo_asignado",
                "motivo": "motivo_reemplazo",
                "por_que_no": "motivo_no_reemplazo",
                "de_acuerdo_reemplazo": "probabilistica"
            })

            st.dataframe(df_cambios, use_container_width=True)

            # Descargar a Excel
            st.download_button(
                "⬇️ Descargar cambios en Excel",
                data=df_cambios.to_csv(index=False).encode("utf-8"),
                file_name="cambios_reportados.csv",
                mime="text/csv"
            )
         else:
            st.info("No se han registrado cambios todavía.")