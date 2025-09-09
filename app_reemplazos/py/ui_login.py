import streamlit as st
from PIL import Image
import os

def show_login(authenticator, message_placeholder):
    with st.sidebar:
        # === Logo ===
        logo_path = os.path.join(os.path.dirname(__file__), "assets", "IDT_logo.png")
        if os.path.exists(logo_path):
            st.image(logo_path, use_container_width=True)

        # === Títulos ===
        st.markdown("# Ingreso al Sistema")
        st.markdown("## Solo usuarios autorizados")

        # === Formulario de login ===
        try:
            authenticator.login(
                'main',
                fields={'Form name': 'Acceso',
                        'Username': 'Usuario',
                        'Password': 'Contraseña',
                        'Login': 'Ingresar'},
                captcha=False
            )
        except Exception as e:
            st.sidebar.error(f"Error en el login: {e}")

    # === Mensajes de error o advertencia ===
    if st.session_state.get('authentication_status') is False:
        message_placeholder.error('Usuario/contraseña incorrectos')
    elif st.session_state.get('authentication_status') is None:
        message_placeholder.warning('Ingrese sus credenciales para acceder al sistema')