import streamlit as st

def load_styles():
    """
    Inyecta estilos CSS globales en la app Streamlit.
    """
    st.markdown(
        """
        <style>
        /* === Estilos generales === */
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f9fafb;
        }

        /* === Encabezados === */
        h1, h2, h3 {
            color: #1f4e79;
        }

        /* === Sidebar === */
        [data-testid="stSidebar"] {
            background-color: #f1f3f6;
            padding-top: 10px;
        }

        [data-testid="stSidebar"] h3 {
            font-size: 18px;
            color: #1f4e79;
            margin-bottom: 5px;
        }

        /* === Botones === */
        .stButton > button {
            background-color: #1f4e79;
            color: white;
            border-radius: 8px;
            border: none;
            padding: 0.6em 1.2em;
            font-weight: 500;
        }
        .stButton > button:hover {
            background-color: #16324f;
            color: #f1f1f1;
        }

        /* === Tablas === */
        .stDataFrame, .stTable {
            border: 1px solid #ddd;
            border-radius: 8px;
        }
        </style>
        """,
        unsafe_allow_html=True
    )

def render_sidebar_logo():
    """
    Renderiza el logo y encabezado en el sidebar.
    """
    st.image("app_reemplazos/py/assets/IDT_logo.png", use_container_width=True)
    st.markdown(
        """
        <div style="text-align:center; margin-top:-10px; margin-bottom:20px;">
            <h3>🔐 Sistema de Reemplazos</h3>
        </div>
        """,
        unsafe_allow_html=True
    )

