import streamlit as st
import yaml
from yaml.loader import SafeLoader
import bcrypt
import os
from db_utils import registrar_cambio
from datetime import datetime


CONFIG_FILE = os.path.join(os.path.dirname(__file__), "config.yaml")

def load_config():
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        return yaml.load(f, Loader=SafeLoader)

def save_config(config):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(config, f, allow_unicode=True, default_flow_style=False)

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def show_user_admin():
    """
    Panel de administración de usuarios: crear, modificar y eliminar
    """
    st.subheader("👥 Gestión de Usuarios")

    config = load_config()
    usuarios = config.get("credentials", {}).get("usernames", {})

    # 📋 Listado de usuarios
    if usuarios:
        st.markdown("### Usuarios actuales")
        st.table([
            {
                "Usuario": u,
                "Nombre": v.get("name"),
                "Email": v.get("email"),
                "Roles": ", ".join(v.get("roles", []))
            }
            for u, v in usuarios.items()
        ])
    else:
        st.info("No hay usuarios registrados todavía.")

    # ➕ Crear usuario
    st.markdown("### ➕ Crear usuario")
    new_user = st.text_input("Usuario (username)")
    new_name = st.text_input("Nombre completo")
    new_email = st.text_input("Correo electrónico")
    new_pass = st.text_input("Contraseña", type="password")
    new_role = st.text_input("Rol (ej: admin, analista, user)")

    if st.button("✅ Crear usuario"):
        if new_user and new_pass:
            if new_user in usuarios:
                st.error("Ese usuario ya existe.")
            else:
                hashed = hash_password(new_pass)
                config["credentials"]["usernames"][new_user] = {
                    "name": new_name,
                    "password": hashed,
                    "email": new_email,
                    "roles": [r.strip() for r in new_role.split(",") if r.strip()]
                }
                save_config(config)
                st.success(f"Usuario **{new_user}** creado.")
                st.rerun()
        else:
            st.error("Debe ingresar al menos usuario y contraseña.")

    # ✏️ Modificar / eliminar usuario existente
    st.markdown("### ✏️ Modificar o eliminar usuario")
    selected_user = st.selectbox("Seleccione un usuario", ["(ninguno)"] + list(usuarios.keys()))

    if selected_user != "(ninguno)":
        user_data = usuarios[selected_user]
        mod_name = st.text_input("Nombre completo", value=user_data.get("name", ""))
        mod_email = st.text_input("Correo electrónico", value=user_data.get("email", ""))
        mod_pass = st.text_input("Nueva contraseña (opcional)", type="password")
        mod_roles = st.text_input("Roles (separados por coma)", value=",".join(user_data.get("roles", [])))

        if st.button("💾 Guardar cambios"):
            if mod_pass:
                user_data["password"] = hash_password(mod_pass)
            user_data["name"] = mod_name
            user_data["email"] = mod_email
            user_data["roles"] = [r.strip() for r in mod_roles.split(",") if r.strip()]
            config["credentials"]["usernames"][selected_user] = user_data
            save_config(config)
            st.success(f"Usuario **{selected_user}** actualizado.")
            st.rerun()

        if st.button("🗑️ Eliminar usuario"):
            del config["credentials"]["usernames"][selected_user]
            save_config(config)
            st.warning(f"Usuario **{selected_user}** eliminado.")
            st.rerun()


def show_user_panel(username):
    """
    Panel para usuarios NO administradores.
    Permite reportar cambios en planillas / UPM.
    """
    st.title("📝 Panel de Usuario")
    st.info(f"Bienvenido {username}, aquí puedes reportar cambios realizados.")

    st.markdown("### 📋 Reportar reemplazo")

    with st.form("form_cambio"):
        nombre_completo = st.text_input("Nombre completo")
        cedula = st.text_input("Cédula")
        planilla = st.text_input("Planilla")
        upm_original = st.text_input("UPM original")
        upm_reemplazo = st.text_input("UPM reemplazo asignado")
        de_acuerdo = st.selectbox("¿Acepta el reemplazo probabilístico?", ["Sí", "No"])
        motivo = st.text_area("Motivo del reemplazo")
        por_que_no = st.text_area("Motivo por el que no usó el reemplazo (si aplica)")

        submitted = st.form_submit_button("✅ Registrar cambio")

        if submitted:
            try:
                registrar_cambio(
                    nombre_completo,
                    cedula,
                    upm_original,
                    upm_reemplazo,
                    de_acuerdo,
                    por_que_no,
                    motivo
                )
                st.success("✅ Cambio registrado correctamente.")
            except Exception as e:
                st.error(f"❌ Error al registrar el cambio: {e}")

    st.markdown("---")
    st.caption(f"Última actualización: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

