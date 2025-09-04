# ============================================================
# Dashboard - versión con gestión segura de usuarios
# ============================================================
# https://shinycomplexsurvey-hhgxnjtb3tjuvuherqwdnt.streamlit.app/
import streamlit as st
import pandas as pd
import yaml
from yaml.loader import SafeLoader
import streamlit_authenticator as stauth
import sqlite3
from datetime import datetime, timedelta
import random
import os
import hashlib


# ============================================================
# CONFIG_INICIAL
# ============================================================
st.set_page_config(page_title="Reemplazos", layout="wide")
message_placeholder = st.empty()  # Para mensajes globales



st.markdown("""
    <style>
        /* Importar fuentes elegantes */
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:wght@400;600;700&display=swap');

        /* Variables CSS - Paleta IDT Bogotá */
        :root {
            --primary-blue: #2E4A8B;           /* Azul institucional IDT */
            --secondary-blue: #4A6BA8;        /* Azul más claro */
            --accent-yellow: #FFDD09;          /* Amarillo oficial IDT */
            --accent-gold: #FFB800;            /* Dorado complementario */
            --success-green: #10B981;          /* Verde éxito */
            --danger-red: #DC2626;             /* Rojo advertencia */
            --background: linear-gradient(135deg, #F8FAFC 0%, #EDF2F7 100%);
            --card-bg: rgba(255, 255, 255, 0.95);
            --shadow-light: 0 2px 4px rgba(46, 74, 139, 0.08);
            --shadow-medium: 0 4px 12px rgba(46, 74, 139, 0.12);
            --shadow-heavy: 0 8px 24px rgba(46, 74, 139, 0.16);
            --border-radius: 8px;
            --text-primary: #1A202C;
            --text-secondary: #4A5568;
        }

        /* Tipografía moderna y legible */
        html, body, [class*="css"] {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            color: var(--text-primary);
            line-height: 1.6;
        }

        /* Fondo principal con gradiente sutil */
        .stApp {
            background: var(--background);
            min-height: 100vh;
        }

        /* Contenedor principal */
        .main .block-container {
            padding-top: 2rem;
            padding-bottom: 2rem;
            max-width: 1200px;
        }

        /* Títulos elegantes - SIN gradiente para mantener emojis naturales */
        h1 {
            font-family: 'Playfair Display', serif;
            font-weight: 700;
            font-size: 2.5rem;
            color: var(--primary-blue);
            margin-bottom: 1rem;
            text-align: center;
        }

        h2 {
            font-family: 'Playfair Display', serif;
            font-weight: 600;
            font-size: 2rem;
            color: var(--primary-blue);
            margin-bottom: 0.8rem;
            border-bottom: 3px solid var(--accent-yellow);
            padding-bottom: 0.5rem;
        }

        h3 {
            font-weight: 600;
            font-size: 1.5rem;
            color: var(--secondary-blue);
            margin-bottom: 0.6rem;
        }

        /* Tarjetas y contenedores estilo IDT */
        .stMarkdown, .stDataFrame, .stPlotlyChart, .stMetric {
            background: var(--card-bg);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(46, 74, 139, 0.1);
            border-radius: var(--border-radius);
            padding: 1.5rem;
            margin-bottom: 1rem;
            box-shadow: var(--shadow-medium);
            transition: all 0.3s ease;
        }

        .stMarkdown:hover, .stDataFrame:hover, .stPlotlyChart:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-heavy);
            border-color: rgba(255, 221, 9, 0.3);
        }

        /* Botones estilo IDT */
        .stButton > button {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--secondary-blue) 100%);
            color: white;
            border: 2px solid transparent;
            border-radius: var(--border-radius);
            padding: 0.75rem 2rem;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: var(--shadow-medium);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .stButton > button:hover {
            background: linear-gradient(135deg, var(--accent-yellow) 0%, var(--accent-gold) 100%);
            color: var(--primary-blue);
            border-color: var(--primary-blue);
            transform: translateY(-2px);
            box-shadow: var(--shadow-heavy);
        }

        .stButton > button:active {
            transform: translateY(0px);
        }

        /* Pestañas estilo IDT */
        .stTabs [data-baseweb="tab-list"] {
            gap: 4px;
            background: var(--card-bg);
            padding: 0.5rem;
            border-radius: var(--border-radius);
            box-shadow: var(--shadow-light);
            border: 1px solid rgba(46, 74, 139, 0.1);
        }

        .stTabs [data-baseweb="tab"] {
            background: transparent;
            border-radius: 6px;
            color: var(--text-secondary);
            font-weight: 500;
            padding: 0.75rem 1.5rem;
            transition: all 0.3s ease;
            border: 1px solid transparent;
        }

        .stTabs [aria-selected="true"] {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--secondary-blue) 100%);
            color: white !important;
            box-shadow: var(--shadow-medium);
            border-color: var(--accent-yellow);
        }

        /* Inputs estilo institucional */
        .stTextInput > div > div > input,
        .stSelectbox > div > div > select {
            background: var(--card-bg);
            border: 2px solid rgba(46, 74, 139, 0.2);
            border-radius: var(--border-radius);
            padding: 0.75rem;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        .stTextInput > div > div > input:focus,
        .stSelectbox > div > div > select:focus {
            border-color: var(--accent-yellow);
            box-shadow: 0 0 0 3px rgba(255, 221, 9, 0.2);
            outline: none;
        }

        /* Sidebar IDT */
        .css-1d391kg {
            background: linear-gradient(180deg, var(--primary-blue) 0%, var(--secondary-blue) 100%);
            border-radius: 0;
        }

        .css-1d391kg .stMarkdown {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            color: white;
            border-radius: var(--border-radius);
        }

        /* DataFrames estilo formal */
        .stDataFrame {
            border: none;
            overflow: hidden;
        }

        .stDataFrame table {
            border-collapse: collapse;
            width: 100%;
        }

        .stDataFrame th {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--secondary-blue) 100%);
            color: white;
            padding: 1rem;
            font-weight: 600;
            text-align: left;
            border: none;
            border-bottom: 2px solid var(--accent-yellow);
        }

        .stDataFrame td {
            padding: 0.75rem 1rem;
            border-bottom: 1px solid rgba(46, 74, 139, 0.1);
            transition: background-color 0.2s ease;
        }

        .stDataFrame tr:hover td {
            background-color: rgba(255, 221, 9, 0.05);
        }

        /* Métricas destacadas */
        .stMetric {
            text-align: center;
            background: linear-gradient(135deg, var(--card-bg) 0%, rgba(255, 221, 9, 0.05) 100%);
            border-left: 4px solid var(--accent-yellow);
        }

        .stMetric [data-testid="metric-container"] > div:first-child {
            font-size: 2rem;
            font-weight: 700;
            color: var(--primary-blue);
        }

        /* Mensajes de estado IDT */
        .stSuccess {
            background: linear-gradient(135deg, rgba(16, 185, 129, 0.1) 0%, rgba(16, 185, 129, 0.05) 100%);
            border-left: 4px solid var(--success-green);
            border-radius: var(--border-radius);
        }

        .stWarning {
            background: linear-gradient(135deg, rgba(255, 221, 9, 0.1) 0%, rgba(255, 221, 9, 0.05) 100%);
            border-left: 4px solid var(--accent-yellow);
            border-radius: var(--border-radius);
        }

        .stError {
            background: linear-gradient(135deg, rgba(220, 38, 38, 0.1) 0%, rgba(220, 38, 38, 0.05) 100%);
            border-left: 4px solid var(--danger-red);
            border-radius: var(--border-radius);
        }

        /* Radio buttons estilo institucional */
        .stRadio > div {
            background: var(--card-bg);
            border-radius: var(--border-radius);
            padding: 1rem;
            border: 1px solid rgba(46, 74, 139, 0.1);
        }

        /* Scrollbar IDT */
        ::-webkit-scrollbar {
            width: 8px;
        }

        ::-webkit-scrollbar-track {
            background: rgba(46, 74, 139, 0.1);
            border-radius: var(--border-radius);
        }

        ::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--accent-yellow) 100%);
            border-radius: var(--border-radius);
        }

        ::-webkit-scrollbar-thumb:hover {
            background: var(--accent-yellow);
        }

        /* Responsividad */
        @media (max-width: 768px) {
            .main .block-container {
                padding: 1rem;
            }
            
            h1 {
                font-size: 2rem;
            }
            
            h2 {
                font-size: 1.5rem;
            }
            
            .stButton > button {
                padding: 0.6rem 1.5rem;
                font-size: 0.9rem;
            }
        }
    </style>
""", unsafe_allow_html=True)


# ============================================================
# RUTA DE ARCHIVOS DE CONFIG
# ============================================================
CONFIG_FILE = "config.yaml"
DB_FILE = "log4.db"

# ============================================================
# CONFIG_UTILS
# ============================================================
def guardar_config(config_obj):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(config_obj, f, default_flow_style=False, allow_unicode=True)


def cargar_config():
    if not os.path.exists(CONFIG_FILE):
        base = {
            "credentials": {"usernames": {}},
            "cookie": {
                "name": "reemplazos_cookie",
                "key": "cambiar_esta_clave_por_una_segura",
                "expiry_days": 30
            },
            "preauthorized": {"emails": []}
        }
        guardar_config(base)
        return base

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        cfg = yaml.load(f, Loader=SafeLoader) or {}
        cfg.setdefault("credentials", {}).setdefault("usernames", {})
        cfg.setdefault("cookie", {
            "name": "reemplazos_cookie",
            "key": "cambiar_esta_clave_por_una_segura",
            "expiry_days": 30
        })
        cfg.setdefault("preauthorized", {"emails": []})

        for uname, uinfo in list(cfg["credentials"]["usernames"].items()):
            if isinstance(uinfo, dict):
                uinfo.setdefault("email", "none")
                if "name" not in uinfo:
                    full = (uinfo.get("first_name", "") + " " + uinfo.get("last_name", "")).strip()
                    uinfo["name"] = full if full else uname
                uinfo.setdefault("roles", ["user"])
            else:
                cfg["credentials"]["usernames"][uname] = {
                    "name": str(uname),
                    "password": str(uinfo),
                    "email": "none",
                    "roles": ["user"]
                }
        return cfg

config = cargar_config()

# ============================================================
# DB_SQLITE
# ============================================================
def get_conn():
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_sqlite_tables():
    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS cambios (
                nombre_completo TEXT,
                cedula TEXT,
                upm_original TEXT,
                upm_reemplazo TEXT,
                de_acuerdo_reemplazo TEXT,
                por_que_no TEXT,
                motivo TEXT,
                fecha TEXT
            )
        """)
        cur.execute("CREATE TABLE IF NOT EXISTS plantilla (upm TEXT)")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS marco (
                FECHA_DESPACHO TEXT,
                HORA_DESPACHO TEXT,
                MUNICIPIO_DESTINO_RUTA TEXT,
                UPM TEXT
            )
        """)
        conn.commit()

init_sqlite_tables()

# ============================================================
# FUNCIONES
# ============================================================
def guardar_base(plantilla, marco, var_upm):
    with get_conn() as conn:
        plantilla_db = pd.DataFrame({"upm": plantilla[var_upm].dropna().astype(str).tolist()})
        plantilla_db.to_sql("plantilla", conn, if_exists="replace", index=False)
        marco.to_sql("marco", conn, if_exists="replace", index=False)
        conn.commit()


def cargar_base():
    with get_conn() as conn:
        try:
            plantilla = pd.read_sql("SELECT * FROM plantilla", conn)
        except Exception:
            plantilla = pd.DataFrame()
        try:
            marco = pd.read_sql("SELECT * FROM marco", conn)
        except Exception:
            marco = pd.DataFrame()
    return plantilla, marco


def registrar_cambio(nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo):
    with get_conn() as conn:
        conn.execute("""
            INSERT INTO cambios 
            (nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo_reemplazo, por_que_no, motivo, fecha)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo,
            datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ))
        conn.commit()


def eliminar_registros_por_rid(rowids):
    with get_conn() as conn:
        conn.executemany("DELETE FROM cambios WHERE rowid = ?", [(rid,) for rid in rowids])
        conn.commit()

# ============================================================
# AUTH_HASH
# ============================================================
def hash_password_compatible(plain_password: str) -> str:
    plain_password = str(plain_password)
    try:
        return stauth.Hasher([plain_password]).generate()[0]
    except Exception:
        pass
    try:
        h = stauth.Hasher([])
        return h.hash(plain_password)
    except Exception:
        pass
    try:
        return stauth.Hasher([plain_password]).hash()[0]
    except Exception:
        pass
    try:
        import bcrypt
        return bcrypt.hashpw(plain_password.encode(), bcrypt.gensalt()).decode()
    except Exception:
        pass
    return hashlib.sha256(plain_password.encode()).hexdigest()

# ============================================================
# AUTH_REGISTER
# ============================================================
def registrar_usuario(username: str, nombre: str, password: str, rol: str = "user"):
    username, nombre, password, rol = (username or "").strip(), (nombre or "").strip(), (password or "").strip(), (rol or "user").strip()
    if not username or not nombre or not password:
        return False, "⚠️ Complete nombre, usuario y contraseña."
    cfg = cargar_config()
    if username in cfg["credentials"]["usernames"]:
        return False, "❌ El usuario ya existe."
    hashed = hash_password_compatible(password)
    cfg["credentials"]["usernames"][username] = {
        "name": nombre,
        "password": hashed,
        "email": "none",
        "roles": [rol]
    }
    guardar_config(cfg)
    return True, "✅ Usuario creado correctamente."

def eliminar_usuario(username: str):
    cfg = cargar_config()
    if username not in cfg["credentials"]["usernames"]:
        return False, "❌ El usuario no existe."
    del cfg["credentials"]["usernames"][username]
    guardar_config(cfg)
    return True, "✅ Usuario eliminado correctamente."

def cambiar_rol_usuario(username: str, nuevo_rol: str):
    cfg = cargar_config()
    if username not in cfg["credentials"]["usernames"]:
        return False, "❌ El usuario no existe."
    cfg["credentials"]["usernames"][username]["roles"] = [nuevo_rol]
    guardar_config(cfg)
    return True, f"✅ Rol cambiado a {nuevo_rol} para el usuario {username}."

# ============================================================
# AUTH_SETUP
# ============================================================
authenticator = stauth.Authenticate(
    config['credentials'],
    config['cookie']['name'],
    config['cookie']['key'],
    config['cookie']['expiry_days']
)

# ============================================================
# PRE-LOGIN - SOLO LOGIN, SIN REGISTRO PÚBLICO
# ============================================================
auth_status = st.session_state.get('authentication_status', None)
username = st.session_state.get('username', None)
user_name_display = st.session_state.get('name', '')

if not auth_status:
    with st.sidebar:
        st.markdown("## 🔑 Ingreso al Sistema")
        st.markdown("*Solo usuarios autorizados*")
        try:
            authenticator.login('main',
                fields={'Form name': 'Acceso', 'Username': 'Usuario', 'Password': 'Contraseña',
                        'Login': 'Ingresar', 'Captcha': 'Captcha'},
                captcha=False
            )
        except Exception as e:
            st.sidebar.error(f"Error en el login: {e}")
else:
    with st.sidebar:
        try:
            authenticator.logout('Cerrar sesión')
        except Exception:
            st.sidebar.button("Cerrar sesión")

# ============================================================
# ESTADO AUTENTICACIÓN
# ============================================================
auth_status = st.session_state.get('authentication_status', None)
username = st.session_state.get('username', None)
user_name_display = st.session_state.get('name', '')

config = cargar_config()
roles = config["credentials"]["usernames"].get(username, {}).get("roles", []) if username else []
is_admin, is_user = "admin" in roles, "user" in roles

# ============================================================
# CONTENIDO PRINCIPAL
# ============================================================
if auth_status:
    st.write(f'Bienvenido {user_name_display} 👋')

    # === PANEL DE ADMINISTRACIÓN ===
    if is_admin:
        st.title("👨‍💼 Panel de Administración")
        
        # Descripción para el administrador
        st.info("""
        "Bienvenido Administrador 👋
        
        Como administrador, usted tiene acceso completo al sistema de gestión de reemplazos de UPM. Sus funciones principales incluyen:
        
        📂 **Cargar Base de Datos:** Subir y gestionar los archivos con la información de UPM y reemplazos disponibles para mantener el sistema actualizado.
        
        💾 **Base Final:** Revisar, validar y exportar la base de datos consolidada con todos los cambios y reemplazos procesados.
        
        👥 **Gestión de Usuarios:** Administrar cuentas de usuario, permisos de acceso y supervisar las solicitudes de cambio realizadas por los operadores.
        
        El objetivo es mantener un control centralizado y eficiente de todos los reemplazos de UPM en la Terminal de Transportes, 
        asegurando la integridad de los datos y la continuidad del servicio."
        """)
        
        tabs = st.tabs(["📂 Cargar Base", "💾 Base Final", "👥 Gestión de Usuarios"])

        # -------- TAB 1: CARGAR BASE --------
        with tabs[0]:
            st.markdown("### 📂 Cargar Base de Datos de UPM y Reemplazos")
            
            try:
                plantilla, marco = cargar_base()
                if not plantilla.empty and not marco.empty:
                    st.success("✅ Actualmente hay una base cargada en el sistema.")
            except Exception:
                st.info("ℹ️ No hay base guardada todavía.")
            
            archivo_excel = st.file_uploader("Suba el archivo Excel:", type=["xlsx"], key="admin_excel")
            
            if archivo_excel:
                xls = pd.ExcelFile(archivo_excel)
                hojas = xls.sheet_names
                
                hoja_upm = st.selectbox("Hoja de UPM principales:", hojas, key="hoja_upm")
                plantilla = pd.read_excel(archivo_excel, sheet_name=hoja_upm)
                var_upm = st.selectbox("Columna con UPM:", plantilla.columns, key="var_upm")
                
                hoja_marco = st.selectbox("Hoja MARCO:", hojas, key="hoja_marco")
                marco = pd.read_excel(archivo_excel, sheet_name=hoja_marco)
                if all(col in marco.columns for col in ["FECHA_DESPACHO","HORA_DESPACHO","MUNICIPIO_DESTINO_RUTA"]):
                    marco["UPM"] = (
                        marco["FECHA_DESPACHO"].astype(str) + "_" +
                        marco["HORA_DESPACHO"].astype(str) + "_" +
                        marco["MUNICIPIO_DESTINO_RUTA"].astype(str)
                    )
                else:
                    st.warning("⚠️ Faltan columnas en MARCO.")

                if st.button("Guardar base en el sistema"):
                    guardar_base(plantilla, marco, var_upm)
                    st.success("✅ Base guardada correctamente.")
                    st.rerun()

        # -------- TAB 2: BASE FINAL --------
        with tabs[1]:
            st.markdown("### 💾 Base de Datos de Cambios Registrados")
            try:
                with get_conn() as conn:
                    df_log = pd.read_sql(
                        """SELECT rowid AS rid, * FROM cambios ORDER BY fecha DESC""",
                        conn
                    )
            except Exception as e:
                st.error(f"Error leyendo historial: {e}")
                df_log = pd.DataFrame()

            if df_log.empty:
                st.info("📝 No hay registros aún")
            else:
                orden = [
                    "nombre_completo","cedula","upm_original","upm_reemplazo",
                    "de_acuerdo_reemplazo","por_que_no","motivo","fecha"
                ]
                df_vista = df_log[orden].rename(columns={
                    "nombre_completo":"NOMBRE USUARIO","cedula":"CÉDULA","upm_original":"UPM ORIGINAL",
                    "upm_reemplazo":"UPM REEMPLAZO","de_acuerdo_reemplazo":"DE ACUERDO CON EL REEMPLAZO",
                    "por_que_no":"POR QUÉ NO","motivo":"MOTIVO DEL REEMPLAZO","fecha":"FECHA"
                })
                st.dataframe(df_vista, use_container_width=True)

                # Descarga CSV
                csv = df_vista.to_csv(index=False).encode('utf-8')
                st.download_button(
                   label="📥 Descargar Base en CSV",
                   data=csv,
                   file_name='registros_de_cambios.csv',
                   mime='text/csv',
                )

                st.markdown("---")  # Separador visual

                registros_display = [
                    f"{row['rid']} - {row['nombre_completo']} ({row['upm_original']} → {row['upm_reemplazo']}) - {row['fecha']}"
                    for _, row in df_log.iterrows()
                ]
                sel_regs = st.multiselect("🗑️ Eliminar registros:", registros_display)

                if sel_regs and st.button("Eliminar seleccionados"):
                    rowids = [int(sel.split(" - ")[0]) for sel in sel_regs]
                    eliminar_registros_por_rid(rowids)
                    st.success("✅ Registros eliminados.")
                    st.rerun()

        # -------- TAB 3: GESTIÓN DE USUARIOS --------
        with tabs[2]:
            st.markdown("### 👥 Gestión de Usuarios")
            
            # Subtabs para organizar mejor
            sub_tabs = st.tabs(["➕ Crear Usuario", "📋 Lista de Usuarios", "✏️ Modificar Usuario"])
            
            # ---- CREAR USUARIO ----
            with sub_tabs[0]:
                st.markdown("#### 🆕 Crear un nuevo usuario")
                with st.form("registro_usuario_admin", clear_on_submit=True):
                    col1, col2 = st.columns(2)
                    with col1:
                        nombre = st.text_input("👤 Nombre completo")
                        nuevo_usuario = st.text_input("📛 Usuario (username)")
                    with col2:
                        nueva_clave = st.text_input("🔒 Contraseña", type="password")
                        rol = st.selectbox("🎭 Rol", ["user", "admin"], help="admin: Acceso completo | user: Solo operaciones")
                    
                    crear_usuario = st.form_submit_button("Crear Usuario", type="primary")
                    
                if crear_usuario:
                    if nombre and nuevo_usuario and nueva_clave:
                        ok, msg = registrar_usuario(nuevo_usuario, nombre, nueva_clave, rol)
                        if ok:
                            st.success(msg)
                        else:
                            st.error(msg)
                    else:
                        st.error("⚠️ Complete todos los campos.")
            
            # ---- LISTA DE USUARIOS ----
            with sub_tabs[1]:
                st.markdown("#### 📋 Usuarios Registrados")
                cfg = cargar_config()
                usuarios = cfg["credentials"]["usernames"]
                
                if usuarios:
                    # Crear DataFrame para mostrar usuarios
                    usuarios_data = []
                    for uname, uinfo in usuarios.items():
                        usuarios_data.append({
                            "Usuario": uname,
                            "Nombre": uinfo.get("name", ""),
                            "Roles": ", ".join(uinfo.get("roles", ["user"])),
                            "Email": uinfo.get("email", "none")
                        })
                    
                    df_usuarios = pd.DataFrame(usuarios_data)
                    st.dataframe(df_usuarios, use_container_width=True)
                    
                    st.metric("Total de Usuarios", len(usuarios))
                else:
                    st.info("ℹ️ No hay usuarios registrados aún.")
            
            # ---- MODIFICAR USUARIO ----
            with sub_tabs[2]:
                st.markdown("#### ✏️ Modificar o Eliminar Usuario")
                cfg = cargar_config()
                usuarios = list(cfg["credentials"]["usernames"].keys())
                
                if usuarios:
                    usuario_seleccionado = st.selectbox("Seleccionar usuario:", usuarios)
                    
                    if usuario_seleccionado:
                        usuario_info = cfg["credentials"]["usernames"][usuario_seleccionado]
                        
                        # Información actual
                        st.markdown("##### 📊 Información Actual")
                        col1, col2, col3 = st.columns(3)
                        col1.metric("Nombre", usuario_info.get("name", ""))
                        col2.metric("Usuario", usuario_seleccionado)
                        col3.metric("Rol Actual", ", ".join(usuario_info.get("roles", ["user"])))
                        
                        st.markdown("---")
                        
                        # Acciones
                        col_accion1, col_accion2 = st.columns(2)
                        
                        with col_accion1:
                            st.markdown("##### 🎭 Cambiar Rol")
                            nuevo_rol = st.selectbox("Nuevo rol:", ["user", "admin"], 
                                                   index=0 if "admin" not in usuario_info.get("roles", []) else 1,
                                                   key="cambio_rol")
                            
                            if st.button("Cambiar Rol", type="primary"):
                                ok, msg = cambiar_rol_usuario(usuario_seleccionado, nuevo_rol)
                                if ok:
                                    st.success(msg)
                                    st.rerun()
                                else:
                                    st.error(msg)
                        
                        with col_accion2:
                            st.markdown("##### 🗑️ Eliminar Usuario")
                            st.warning("⚠️ Esta acción no se puede deshacer.")
                            
                            # Protección: no permitir eliminar al usuario actual
                            if usuario_seleccionado == username:
                                st.error("❌ No puedes eliminar tu propio usuario.")
                            else:
                                if st.button("Eliminar Usuario", type="secondary"):
                                    ok, msg = eliminar_usuario(usuario_seleccionado)
                                    if ok:
                                        st.success(msg)
                                        st.rerun()
                                    else:
                                        st.error(msg)
                else:
                    st.info("ℹ️ No hay usuarios para modificar.")

        # Detener aquí para que no se muestre el contenido de usuarios
        st.stop()

    # === PANEL DE USUARIO ===
    elif is_user:
        st.title("🚌 Control de Cambios - Terminal de Transportes")
        
        # Descripción para el usuario
        st.info("""
                    "Como usuario, usted debe completar este formulario para solicitar el cambio de su UPM (Unidad Primaria de Muestreo) actual por una nueva disponible. 
                El objetivo es gestionar de manera eficiente los reemplazos cuando su ruta asignada no esté programada o presente algún inconveniente, 
                asegurando así la continuidad del servicio en la Terminal de Transportes."
    """)
        st.subheader("🔄 Selección de UPM y Reemplazos")


        try:
            plantilla, marco = cargar_base()
        except Exception:
            plantilla, marco = pd.DataFrame(), pd.DataFrame()
            st.warning("⚠️ No hay base cargada.")

        if not plantilla.empty:
            st.markdown("### Información del solicitante")
            col_a, col_b = st.columns(2)
            nombre_completo = col_a.text_input("👤 Nombre completo:", key="nombre_input")
            cedula = col_b.text_input("🪪 Cédula:", key="cedula_input")

            upm_values = sorted(plantilla["upm"].dropna().astype(str).unique().tolist())
            upm_sel_display = st.selectbox("Seleccione el UPM:", ["— Seleccione —"] + upm_values, key="upm_sel")
            upm_sel = None if upm_sel_display == "— Seleccione —" else upm_sel_display

            # Generar nuevas opciones si cambia la UPM
            if upm_sel and (st.session_state.get("last_upm") != upm_sel):
                try:
                    fecha_original, hora_original, _ = upm_sel.split("_", 2)
                    fecha_dt = datetime.strptime(fecha_original, "%Y-%m-%d")
                    fecha_limite = fecha_dt + timedelta(days=2)
                    
                    candidatos = (
                        marco.loc[marco["HORA_DESPACHO"].astype(str) == hora_original, "UPM"]
                        .dropna()
                        .astype(str)
                        .unique()
                        .tolist()
                        if not marco.empty else []
                    )
                    candidatos_validos = [
                        c for c in candidatos
                        if fecha_dt <= datetime.strptime(c.split("_")[0], "%Y-%m-%d") <= fecha_limite and c != upm_sel
                    ]
                    
                    st.session_state.candidatos_validos = candidatos_validos
                    st.session_state.opciones_reemplazo = random.sample(candidatos_validos, min(3, len(candidatos_validos)))
                    st.session_state.mostrados = set(st.session_state.opciones_reemplazo)
                    st.session_state.last_upm = upm_sel
                except Exception as e:
                    st.error(f"Error procesando UPM: {e}")

            opciones = st.session_state.get("opciones_reemplazo", [])
            
            if opciones:
                reemplazo_sel = st.radio("Seleccione reemplazo:", opciones, key="reemplazo_radio")
                de_acuerdo = st.radio("¿Está de acuerdo?", ["Sí", "No"], key="acuerdo_radio", horizontal=True)
                
                por_que_no, motivo = "", ""

                if de_acuerdo == "No":
                    # Usamos un área de texto para más espacio
                    por_que_no_texto = st.text_area(
                        "Explique por qué no (mínimo 50 caracteres):", 
                        key="porque_no_input",
                        height=150
                    )
                    
                    # Botón para solicitar nuevas opciones
                    if st.button("🔄 Mostrar nuevas opciones"):
                        if len(por_que_no_texto.strip()) < 50:
                            st.error("❌ Explicación demasiado corta. Debe tener al menos 50 caracteres.")
                        else:
                            # 🔥 Registrar SIEMPRE el rechazo cada vez que se piden nuevas opciones
                            registrar_cambio(
                                nombre_completo, cedula, upm_sel, None,
                                "No", por_que_no_texto, "Rechazo de reemplazo"
                            )
                            st.toast("📝 Razón de rechazo registrada.")

                            # Lógica para mostrar nuevas opciones
                            restantes = [c for c in st.session_state.candidatos_validos if c not in st.session_state.mostrados]
                            if restantes:
                                nuevas = random.sample(restantes, min(3, len(restantes)))
                                st.session_state.opciones_reemplazo = nuevas
                                st.session_state.mostrados.update(nuevas)
                                st.rerun()
                            else:
                                st.warning("No hay más opciones disponibles.")
                
                else:  # Si el usuario está de acuerdo
                    motivos = [
                        "La ruta no salió programada",
                        "Inconvenientes en la vía",
                        "Fallas técnicas en el bus",
                        "Reajuste operativo",
                        "Otro"
                    ]
                    motivo_sel = st.selectbox("Motivo del cambio:", motivos, key="motivo_sel")
                    motivo = st.text_input("✍️ Motivo:", key="motivo_otro") if motivo_sel == "Otro" else motivo_sel

                # Botón final para registrar el cambio definitivo
                if st.button("Registrar Cambio"):
                    if not nombre_completo.strip() or not cedula.strip():
                        st.warning("Complete nombre y cédula.")
                    elif not upm_sel or not reemplazo_sel:
                        st.warning("Seleccione UPM válido.")
                    elif de_acuerdo == "No":
                        st.warning("Si no está de acuerdo, debe explicar por qué y presionar 'Mostrar nuevas opciones'.")
                    else:
                        # Solo registrar si está de acuerdo, ya que el 'No' se registra al pedir nuevas opciones
                        if de_acuerdo == "Sí":
                            registrar_cambio(nombre_completo, cedula, upm_sel, reemplazo_sel, de_acuerdo, "", motivo)
                        
                        st.success("Peración finalizada y registrada.")
                        
                        # Limpieza completa de la sesión
                        keys_to_clear = [
                            "nombre_input", "cedula_input", "upm_sel", "acuerdo_radio", 
                            "porque_no_input", "motivo_sel", "motivo_otro", 
                            "opciones_reemplazo", "reemplazo_radio", "last_upm", 
                            "candidatos_validos", "mostrados"
                        ]
                        for key in keys_to_clear:
                            st.session_state.pop(key, None)
                        st.rerun()
            
            elif upm_sel:  # Se activa si se seleccionó UPM pero no hay opciones
                st.info("⚠️ No se encontraron reemplazos para la UPM seleccionada.")

    else:
        # Usuario sin rol específico
        st.warning("Su usuario no tiene permisos asignados. Contacte al administrador.")

else:
    # No autenticado
    st.title("Gestión de Reemplazos de UPM - Terminal de Transportes")
    if auth_status is False:
        message_placeholder.error('Usuario/contraseña incorrectos')
    elif auth_status is None:
        message_placeholder.warning('Ingrese sus credenciales para acceder al sistema')
        
    else:
    # No autenticado
     st.title("Gestión de Reemplazos de UPM - Terminal de Transportes")
    
    # Descripción de la herramienta
    st.markdown("""
        <div style="text-align: center; margin: 2rem 0; padding: 1.5rem; 
                    background: var(--card-bg); border-radius: var(--border-radius); 
                    box-shadow: var(--shadow-medium); border-left: 4px solid var(--accent-yellow);">
            <p style="font-size: 1.1rem; color: var(--text-secondary); line-height: 1.6; margin: 0;">
                "Esta herramienta permite gestionar de manera eficiente los reemplazos de Unidades Primarias de Muestreo (UPM) en la Terminal de Transportes, 
                simplificando el control de cambios y la organización de la información."
            </p>
        </div>
    """, unsafe_allow_html=True)
    
    if auth_status is False:
        message_placeholder.error('Usuario/contraseña incorrectos')
    elif auth_status is None:
        message_placeholder.warning('Ingrese sus credenciales para acceder al sistema')


from PIL import Image

# Cargar la imagen
logo = Image.open("IDT_logo.png")

# Centrar la imagen usando columnas
col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    st.image(logo, width=400)  # Ajusta el valor 150 a tu preferencia
