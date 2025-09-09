import streamlit_authenticator as stauth
import hashlib
from config_utils import cargar_config, guardar_config

def hash_password_compatible(plain_password: str) -> str:
    try: return stauth.Hasher([plain_password]).generate()[0]
    except: return hashlib.sha256(plain_password.encode()).hexdigest()

def registrar_usuario(username: str, nombre: str, password: str, rol: str = "user"):
    cfg = cargar_config()
    if username in cfg["credentials"]["usernames"]: return False, "❌ El usuario ya existe."
    hashed = hash_password_compatible(password)
    cfg["credentials"]["usernames"][username] = {"name": nombre,"password": hashed,"email": "none","roles": [rol]}
    guardar_config(cfg)
    return True, "✅ Usuario creado correctamente."

def eliminar_usuario(username: str):
    cfg = cargar_config()
    if username not in cfg["credentials"]["usernames"]: return False, "❌ El usuario no existe."
    del cfg["credentials"]["usernames"][username]; guardar_config(cfg)
    return True, "✅ Usuario eliminado correctamente."

def cambiar_rol_usuario(username: str, nuevo_rol: str):
    cfg = cargar_config()
    if username not in cfg["credentials"]["usernames"]: return False, "❌ El usuario no existe."
    cfg["credentials"]["usernames"][username]["roles"] = [nuevo_rol]; guardar_config(cfg)
    return True, f"✅ Rol cambiado a {nuevo_rol}."

def init_authenticator(config):
    return stauth.Authenticate(config['credentials'],config['cookie']['name'],config['cookie']['key'],config['cookie']['expiry_days'])