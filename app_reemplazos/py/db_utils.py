import sqlite3
import pandas as pd
from datetime import datetime

DB_FILE = "app_reemplazos/py/log4.db"

def get_conn():
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_sqlite_tables():
    with get_conn() as conn:
        cur = conn.cursor()

        # 🔹 Elimina la tabla vieja 'cambios' si existe
        cur.execute("DROP TABLE IF EXISTS cambios")

        # 🔹 Crea la nueva tabla con la estructura final
        cur.execute("""
            CREATE TABLE IF NOT EXISTS cambios (
                usuario TEXT,
                planilla_original TEXT,
                planilla_reemplazo TEXT,
                probabilistica TEXT,
                upm_reemplazo TEXT,
                departamento_reemplazo TEXT,
                municipio_reemplazo TEXT,
                hora_reemplazo TEXT,
                motivo_reemplazo TEXT,
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

        cur.execute("""
            CREATE TABLE IF NOT EXISTS muestra (
                PLANILLA TEXT,
                MODULO TEXT,
                ESTRATO TEXT,
                UPM TEXT,
                FECHA TEXT,
                LUGAR_DE_APLICACION TEXT,
                EMPRESA TEXT,
                DESTINO TEXT,
                DEPTO TEXT
            )
        """)

        conn.commit()


import streamlit as st  # Para feedback si se usa en Streamlit

def guardar_bases(df_remplazo, df_marco, df_muestra, df_municipios=None, var_upm="UPM"):
    """
    Guarda los DataFrames en la base de datos SQLite.
    Crea/reemplaza las tablas 'reemplazo', 'marco', 'muestra' y opcionalmente 'municipios'.
    """
    try:
        with get_conn() as conn:
            # === 1. Guardar la tabla 'reemplazo' ===
            df_remplazo.to_sql("reemplazo", conn, if_exists="replace", index=False)
            print("Tabla 'reemplazo' guardada exitosamente.")

            # === 2. Guardar la tabla 'marco' ===
            df_marco.to_sql("marco", conn, if_exists="replace", index=False)
            print("Tabla 'marco' guardada exitosamente.")

            # === 3. Guardar la tabla 'muestra' ===
            df_muestra.to_sql("muestra", conn, if_exists="replace", index=False)
            print("Tabla 'muestra' guardada exitosamente.")

            # === 4. Guardar la tabla 'municipios' (si existe) ===
            if df_municipios is not None:
                df_municipios.to_sql(
                    name="municipios",
                    con=conn,
                    if_exists="replace",
                    index=False
                )

            conn.commit()
            return True, "Tablas guardadas correctamente en la base de datos."

    except Exception as e:
        print(f"Error al guardar las bases de datos: {e}")
        return False, f"Error: {e}"

def cargar_bases():
    with get_conn() as conn:
        try:
            plantilla = pd.read_sql("SELECT * FROM plantilla", conn)
        except:
            plantilla = pd.DataFrame()

        try:
            marco = pd.read_sql("SELECT * FROM marco", conn)
        except:
            marco = pd.DataFrame()

        try:
            muestra = pd.read_sql("SELECT * FROM muestra", conn)
        except:
            muestra = pd.DataFrame()

    return plantilla, marco, muestra

def registrar_cambio(usuario, planilla_original, planilla_reemplazo,
                     upm_reemplazo, departamento_reemplazo,
                     municipio_reemplazo, hora_reemplazo,
                     motivo_reemplazo, probabilistica):
    """
    Registra un cambio en la tabla 'cambios' de la base de datos.
    """
    with get_conn() as conn:
        conn.execute("""
            INSERT INTO cambios (
                usuario, planilla_original, planilla_reemplazo,
                probabilistica, upm_reemplazo, departamento_reemplazo,
                municipio_reemplazo, hora_reemplazo, motivo_reemplazo, fecha
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            usuario,
            planilla_original,
            planilla_reemplazo,
            str(probabilistica),
            upm_reemplazo,
            departamento_reemplazo,
            municipio_reemplazo,
            hora_reemplazo,
            motivo_reemplazo,
            datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        ))
        conn.commit()

def eliminar_registros_por_rid(rowids):
    with get_conn() as conn:
        conn.executemany("DELETE FROM cambios WHERE rowid = ?", [(rid,) for rid in rowids])
        conn.commit()

def cargar_cambios():
    """
    Retorna un DataFrame con todos los cambios registrados, incluyendo el rowid.
    """
    with get_conn() as conn:
        try:
            df = pd.read_sql("SELECT rowid, * FROM cambios", conn)
        except:
            df = pd.DataFrame()
    return df


# Inicializar las tablas al cargar
init_sqlite_tables()
