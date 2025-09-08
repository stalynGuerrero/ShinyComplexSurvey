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
    """Guarda el objeto de configuración en un archivo YAML."""
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(config_obj, f, default_flow_style=False, allow_unicode=True)


def cargar_config():
    """Carga el archivo de configuración o crea uno por defecto si no existe."""
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
    """Establece la conexión a la base de datos SQLite."""
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_sqlite_tables():
    """Inicializa las tablas de la base de datos si no existen."""
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
                tipo_reemplazo TEXT,  -- Nueva columna para identificar el tipo de reemplazo
                fecha TEXT
            )
        """)
        cur.execute("CREATE TABLE IF NOT EXISTS plantilla (upm TEXT, departamento TEXT, municipio TEXT, planilla TEXT)") # Columnas adicionales para la plantilla
        cur.execute("""
            CREATE TABLE IF NOT EXISTS marco (
                FECHA_DESPACHO TEXT,
                HORA_DESPACHO TEXT,
                MUNICIPIO_DESTINO_RUTA TEXT,
                UPM TEXT
            )
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS reemplazos_probabilisticos (
                upm_original TEXT,
                upm_reemplazo TEXT
            )
        """)
        conn.commit()

init_sqlite_tables()

# ============================================================
# FUNCIONES
# ============================================================
def guardar_base(plantilla, marco, reemplazos_prob, var_upm, var_depto, var_muni, var_planilla, var_upm_prob_original, var_upm_prob_reemplazo):
    """Guarda las bases de datos de plantilla, marco y reemplazos en SQLite."""
    with get_conn() as conn:
        plantilla_db = pd.DataFrame({
            "upm": plantilla[var_upm].dropna().astype(str).tolist(),
            "departamento": plantilla[var_depto].dropna().astype(str).tolist(),
            "municipio": plantilla[var_muni].dropna().astype(str).tolist(),
            "planilla": plantilla[var_planilla].dropna().astype(str).tolist()
        })
        plantilla_db.to_sql("plantilla", conn, if_exists="replace", index=False)
        marco.to_sql("marco", conn, if_exists="replace", index=False)
        
        reemplazos_prob_db = pd.DataFrame({
            "upm_original": reemplazos_prob[var_upm_prob_original].dropna().astype(str).tolist(),
            "upm_reemplazo": reemplazos_prob[var_upm_prob_reemplazo].dropna().astype(str).tolist()
        })
        reemplazos_prob_db.to_sql("reemplazos_probabilisticos", conn, if_exists="replace", index=False)
        
        conn.commit()


def cargar_base():
    """Carga las bases de datos de plantilla y marco desde SQLite."""
    with get_conn() as conn:
        try:
            plantilla = pd.read_sql("SELECT * FROM plantilla", conn)
        except Exception:
            plantilla = pd.DataFrame()
        try:
            marco = pd.read_sql("SELECT * FROM marco", conn)
        except Exception:
            marco = pd.DataFrame()
        try:
            reemplazos_prob = pd.read_sql("SELECT * FROM reemplazos_probabilisticos", conn)
        except Exception:
            reemplazos_prob = pd.DataFrame()
    return plantilla, marco, reemplazos_prob


def registrar_cambio(nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo, tipo_reemplazo):
    """Registra un cambio de UPM en la base de datos."""
    with get_conn() as conn:
        conn.execute("""
            INSERT INTO cambios 
            (nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo_reemplazo, por_que_no, motivo, tipo_reemplazo, fecha)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo, tipo_reemplazo,
            datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ))
        conn.commit()


def eliminar_registros_por_rid(rowids):
    """Elimina registros de la base de datos por su ID de fila."""
    with get_conn() as conn:
        conn.executemany("DELETE FROM cambios WHERE rowid = ?", [(rid,) for rid in rowids])
        conn.commit()

# ============================================================
# AUTH_HASH
# ============================================================
def hash_password_compatible(plain_password: str) -> str:
    """Hashea la contraseña de manera compatible con Streamlit Authenticator."""
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
    """Registra un nuevo usuario en la configuración de la app."""
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
    """Elimina un usuario de la configuración de la app."""
    cfg = cargar_config()
    if username not in cfg["credentials"]["usernames"]:
        return False, "❌ El usuario no existe."
    del cfg["credentials"]["usernames"][username]
    guardar_config(cfg)
    return True, "✅ Usuario eliminado correctamente."

def cambiar_rol_usuario(username: str, nuevo_rol: str):
    """Cambia el rol de un usuario en la configuración de la app."""
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
            authenticator.login('main', fields={'Form name': 'Acceso', 'Username': 'Usuario', 'Password': 'Contraseña', 'Login': 'Ingresar', 'Captcha': 'Captcha'}, captcha=False
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
        st.info("""
        "Bienvenido Administrador 👋 Como administrador, usted tiene acceso completo al sistema de gestión de reemplazos de UPM. Sus funciones principales incluyen:
        📂 **Cargar Base de Datos:** Subir y gestionar los archivos con la información de UPM y reemplazos disponibles para mantener el sistema actualizado.
        💾 **Base Final:** Revisar, validar y exportar la base de datos consolidada con todos los cambios y reemplazos procesados.
        👥 **Gestión de Usuarios:** Administrar cuentas de usuario, permisos de acceso y supervisar las solicitudes de cambio realizadas por los operadores.
        El objetivo es mantener un control centralizado y eficiente de todos los reemplazos de UPM en la Terminal de Transportes, asegurando la integridad de los datos y la continuidad del servicio."
        """)
        
        tabs = st.tabs(["📂 Cargar Base", "💾 Base Final", "👥 Gestión de Usuarios"])
        
        # -------- TAB 1: CARGAR BASE --------
        with tabs[0]:
            st.markdown("### 📂 Cargar Base de Datos de UPM y Reemplazos")
            try:
                plantilla, marco, reemplazos_prob = cargar_base()
                if not plantilla.empty and not marco.empty:
                    st.success("✅ Actualmente hay una base cargada en el sistema.")
            except Exception:
                st.info("ℹ️ No hay base guardada todavía.")

            archivo_excel = st.file_uploader("Suba el archivo Excel:", type=["xlsx"], key="admin_excel")
            if archivo_excel:
                xls = pd.ExcelFile(archivo_excel)
                hojas = xls.sheet_names
                
                # Mapeo de columnas para la plantilla de reemplazos
                st.markdown("---")
                st.markdown("#### Mapeo de la Hoja de Plantilla")
                hoja_upm = st.selectbox("Hoja de Plantilla:", hojas, key="hoja_upm")
                plantilla_df = pd.read_excel(archivo_excel, sheet_name=hoja_upm)
                
                var_upm = st.selectbox("Columna con UPM:", plantilla_df.columns, key="var_upm")
                var_depto = st.selectbox("Columna con Departamento:", plantilla_df.columns, key="var_depto")
                var_muni = st.selectbox("Columna con Municipio:", plantilla_df.columns, key="var_muni")
                var_planilla = st.selectbox("Columna con Planilla:", plantilla_df.columns, key="var_planilla")

                # Mapeo de columnas para el marco muestral
                st.markdown("---")
                st.markdown("#### Mapeo de la Hoja de Marco Muestral")
                hoja_marco = st.selectbox("Hoja Marco:", hojas, key="hoja_marco")
                marco_df = pd.read_excel(archivo_excel, sheet_name=hoja_marco)
                
                if all(col in marco_df.columns for col in ["FECHA_DESPACHO", "HORA_DESPACHO", "MUNICIPIO_DESTINO_RUTA"]):
                    marco_df["UPM"] = (
                        marco_df["FECHA_DESPACHO"].astype(str) + "_" + marco_df["HORA_DESPACHO"].astype(str) + "_" + marco_df["MUNICIPIO_DESTINO_RUTA"].astype(str)
                    )
                else:
                    st.warning("⚠️ Faltan columnas en MARCO. Se requieren: FECHA_DESPACHO, HORA_DESPACHO, MUNICIPIO_DESTINO_RUTA.")
                
                # Mapeo de columnas para reemplazos probabilísticos
                st.markdown("---")
                st.markdown("#### Mapeo de la Hoja de Reemplazos Probabilísticos")
                hoja_reemplazo_prob = st.selectbox("Hoja de Reemplazos Probabilísticos:", hojas, key="hoja_reemplazo_prob")
                reemplazos_prob_df = pd.read_excel(archivo_excel, sheet_name=hoja_reemplazo_prob)
                
                var_upm_prob_original = st.selectbox("Columna UPM Original (Reemplazos Probabilísticos):", reemplazos_prob_df.columns, key="var_upm_prob_original")
                var_upm_prob_reemplazo = st.selectbox("Columna UPM Reemplazo (Reemplazos Probabilísticos):", reemplazos_prob_df.columns, key="var_upm_prob_reemplazo")

                if st.button("Guardar base en el sistema"):
                    guardar_base(plantilla_df, marco_df, reemplazos_prob_df, var_upm, var_depto, var_muni, var_planilla, var_upm_prob_original, var_upm_prob_reemplazo)
                    st.success("✅ Base guardada correctamente.")
                    st.rerun()

        # -------- TAB 2: BASE FINAL --------
        with tabs[1]:
            st.markdown("### 💾 Base de Datos de Cambios Registrados")
            try:
                with get_conn() as conn:
                    df_log = pd.read_sql(
                        """SELECT rowid AS rid, * FROM cambios ORDER BY fecha DESC""", conn
                    )
            except Exception as e:
                st.error(f"Error leyendo historial: {e}")
                df_log = pd.DataFrame()

            if df_log.empty:
                st.info("📝 No hay registros aún")
            else:
                orden = [
                    "nombre_completo","cedula","upm_original","upm_reemplazo",
                    "de_acuerdo_reemplazo","por_que_no","motivo","tipo_reemplazo","fecha"
                ]
                df_vista = df_log[orden].rename(columns={
                    "nombre_completo": "NOMBRE USUARIO",
                    "cedula": "CÉDULA",
                    "upm_original": "UPM ORIGINAL",
                    "upm_reemplazo": "UPM REEMPLAZO",
                    "de_acuerdo_reemplazo": "DE ACUERDO CON EL REEMPLAZO",
                    "por_que_no": "POR QUÉ NO",
                    "motivo": "MOTIVO DEL REEMPLAZO",
                    "tipo_reemplazo": "TIPO DE REEMPLAZO",
                    "fecha": "FECHA"
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
                
                st.markdown("---")
                
                # Opciones para eliminar registros
                registros_display = [
                    f"{row['rid']} - {row['nombre_completo']} ({row['upm_original']} -> {row['upm_reemplazo']})"
                    for _, row in df_log.iterrows()
                ]
                registros_a_eliminar = st.multiselect("Seleccione los registros a eliminar:", registros_display, key="eliminar_registros_admin")
                
                if st.button("Eliminar registros seleccionados"):
                    rids = [int(r.split(" - ")[0]) for r in registros_a_eliminar]
                    eliminar_registros_por_rid(rids)
                    st.success("✅ Registros eliminados correctamente.")
                    st.rerun()

        # -------- TAB 3: GESTIÓN DE USUARIOS --------
        with tabs[2]:
            st.markdown("### 👥 Gestión de Usuarios")
            st.write("Crea, edita o elimina usuarios del sistema.")
            
            opcion_gestion = st.radio("Acción:", ["Crear Usuario", "Cambiar Rol", "Eliminar Usuario"])
            
            usuarios_existentes = list(config["credentials"]["usernames"].keys())
            
            if opcion_gestion == "Crear Usuario":
                with st.form("form_crear_usuario"):
                    st.subheader("Crear un nuevo usuario")
                    nuevo_usuario = st.text_input("Nombre de usuario:", key="crear_user")
                    nombre_completo = st.text_input("Nombre completo:", key="crear_name")
                    nueva_contraseña = st.text_input("Contraseña:", type="password", key="crear_pass")
                    rol_nuevo = st.selectbox("Rol:", ["user", "admin"], key="crear_rol")
                    submit_crear = st.form_submit_button("Crear usuario")
                    if submit_crear:
                        exito, mensaje = registrar_usuario(nuevo_usuario, nombre_completo, nueva_contraseña, rol_nuevo)
                        st.success(mensaje) if exito else st.error(mensaje)
                        st.rerun()

            elif opcion_gestion == "Cambiar Rol":
                with st.form("form_cambiar_rol"):
                    st.subheader("Cambiar rol de usuario")
                    usuario_cambiar_rol = st.selectbox("Seleccione usuario:", usuarios_existentes, key="cambiar_rol_user")
                    nuevo_rol = st.selectbox("Nuevo rol:", ["user", "admin"], key="cambiar_rol")
                    submit_cambiar_rol = st.form_submit_button("Cambiar rol")
                    if submit_cambiar_rol:
                        exito, mensaje = cambiar_rol_usuario(usuario_cambiar_rol, nuevo_rol)
                        st.success(mensaje) if exito else st.error(mensaje)
                        st.rerun()

            elif opcion_gestion == "Eliminar Usuario":
                with st.form("form_eliminar_usuario"):
                    st.subheader("Eliminar un usuario")
                    usuario_eliminar = st.selectbox("Seleccione usuario:", usuarios_existentes, key="eliminar_user")
                    submit_eliminar = st.form_submit_button("Eliminar usuario")
                    if submit_eliminar:
                        exito, mensaje = eliminar_usuario(usuario_eliminar)
                        st.success(mensaje) if exito else st.error(mensaje)
                        st.rerun()
        
    # === PANEL DE USUARIO ===
    elif is_user:
        st.title("👤 Gestión de Reemplazos de UPM")
        st.info("Utilice esta herramienta para registrar y gestionar los reemplazos de UPM.")

        plantilla, marco, reemplazos_prob = cargar_base()
        
        # Mapeo de bases de datos para el usuario
        if not plantilla.empty and not marco.empty:
            st.markdown("---")
            st.markdown("### 📝 Datos de la UPM a Reemplazar")
            
            # Asegurar que las columnas existen antes de usarlas
            if "upm" in plantilla.columns and "departamento" in plantilla.columns and "municipio" in plantilla.columns:
                upm_original = st.selectbox("Seleccione UPM original:", plantilla["upm"].unique())
                
                # Obtener información de la UPM original
                datos_upm = plantilla[plantilla["upm"] == upm_original].iloc[0]
                st.info(f"""
                **Detalles de la UPM seleccionada:**
                * **Departamento:** {datos_upm['departamento']}
                * **Municipio:** {datos_upm['municipio']}
                * **Planilla:** {datos_upm.get('planilla', 'N/A')}
                """)
                
                # Proponer un reemplazo según la lógica probabilística o manual
                st.markdown("---")
                st.markdown("### ➡️ Asignación de Reemplazo")
                
                reemplazo_prob_row = reemplazos_prob[reemplazos_prob["upm_original"] == upm_original]
                
                if not reemplazo_prob_row.empty:
                    # Es un reemplazo probabilístico
                    upm_reemplazo = reemplazo_prob_row["upm_reemplazo"].iloc[0]
                    tipo_reemplazo_opcion = "Probabilístico"
                    st.success(f"El reemplazo asignado automáticamente es: **{upm_reemplazo}**")
                    st.info(f"Tipo de reemplazo: **{tipo_reemplazo_opcion}**")
                    
                else:
                    # No es probabilístico, se debe seleccionar manualmente
                    st.warning("⚠️ No se encontró un reemplazo probabilístico. Debe seleccionar uno manualmente.")
                    
                    # === Lógica nueva: filtrar UPMs por hora ===
                    if not marco.empty and "UPM" in marco.columns and "HORA_DESPACHO" in marco.columns:
                        # Obtener la hora de la UPM original del marco
                        upm_original_marco = marco[marco["UPM"] == upm_original]
                        if not upm_original_marco.empty:
                            hora_original = upm_original_marco.iloc[0]["HORA_DESPACHO"]
                            
                            # Filtrar UPMs del marco que tengan la misma hora
                            upms_filtradas = marco[
                                (marco["HORA_DESPACHO"] == hora_original) &
                                (marco["UPM"] != upm_original) # Excluir la UPM original
                            ]
                            upms_disponibles = list(upms_filtradas["UPM"].unique())
                        
                            if not upms_disponibles:
                                st.error(f"❌ No hay UPMs disponibles para reemplazo a la hora '{hora_original}'.")
                            else:
                                upm_reemplazo = st.selectbox(
                                    f"Seleccione la UPM de reemplazo manualmente (misma hora: {hora_original}):",
                                    upms_disponibles
                                )
                                tipo_reemplazo_opcion = "No probabilístico (manual)"
                                st.info(f"Tipo de reemplazo: **{tipo_reemplazo_opcion}**")
                        else:
                            st.error(f"❌ La UPM original seleccionada ('{upm_original}') no se encontró en el marco muestral. No se puede asignar un reemplazo.")
                    else:
                        st.error("❌ El marco muestral no está cargado o no tiene las columnas correctas.")


                if st.button("Registrar reemplazo"):
                    if not 'upm_reemplazo' in locals() and not 'upm_reemplazo' in globals():
                        st.error("⚠️ Por favor, seleccione una UPM de reemplazo antes de registrar.")
                    else:
                        motivo_general = st.text_area("Motivo general del reemplazo:", key="motivo_general")
                        if not motivo_general:
                            st.error("Por favor, ingrese un motivo general para el reemplazo.")
                        else:
                            de_acuerdo = st.radio("¿Está de acuerdo con este reemplazo?", ["Sí", "No"])
                            motivo_no_de_acuerdo = ""
                            if de_acuerdo == "No":
                                st.markdown("---")
                                st.markdown("#### Motivo del No Acuerdo")
                                motivo_no_de_acuerdo = st.text_area("Por favor, especifique por qué no está de acuerdo:")
                            
                            registrar_cambio(
                                nombre_completo=user_name_display,
                                cedula=username,
                                upm_original=upm_original,
                                upm_reemplazo=upm_reemplazo,
                                de_acuerdo=de_acuerdo,
                                por_que_no=motivo_no_de_acuerdo,
                                motivo=motivo_general,
                                tipo_reemplazo=tipo_reemplazo_opcion
                            )
                            
                            # Impresión de información clave
                            st.success(f"""
                            ¡Reemplazo registrado con éxito!
                            
                            **Información del reemplazo:**
                            * **Planilla:** {datos_upm.get('planilla', 'N/A')}
                            * **UPM:** {datos_upm['upm']}
                            * **Departamento:** {datos_upm['departamento']}
                            * **Municipio:** {datos_upm['municipio']}
                            """)
                            st.rerun()

            else:
                st.warning("⚠️ No hay bases de datos cargadas. Por favor, contacte a un administrador.")
    
    # === MANEJO DE ESTADO DE AUTENTICACIÓN ===
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
try:
    logo = Image.open("IDT_logo.png")
    st.sidebar.image(logo)
except FileNotFoundError:
    st.sidebar.warning("Logo no encontrado. Asegúrese de que 'IDT_logo.png' esté en 'app_reemplazos/'")
