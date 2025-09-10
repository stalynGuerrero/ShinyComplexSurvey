import streamlit as st
from styles import load_styles, render_sidebar_logo
from config_utils import cargar_config
from auth_utils import init_authenticator
from ui_login import show_login
from ui_admin import show_admin_panel
from ui_user import show_user_panel   

st.set_page_config(page_title="Reemplazos", layout="wide")
message_placeholder = st.empty()

# Cargar estilos
load_styles()

# Configuración y autenticación
config = cargar_config()
authenticator = init_authenticator(config)

auth_status = st.session_state.get("authentication_status", None)
username = st.session_state.get("username", None)
user_name_display = st.session_state.get("name", "")

if not auth_status:
    show_login(authenticator, message_placeholder)

else:
    roles = config["credentials"]["usernames"].get(username, {}).get("roles", []) if username else []
    is_admin, is_user = "admin" in roles, "user" in roles

    st.write(f"Bienvenido 👋")

    if is_admin:
        show_admin_panel(username, authenticator)

    elif is_user:
        show_user_panel(username, authenticator)

    else:
        st.warning("Su usuario no tiene permisos asignados. Contacte al administrador.")