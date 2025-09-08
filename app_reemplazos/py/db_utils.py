import sqlite3, pandas as pd
from datetime import datetime

DB_FILE = "log4.db"

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

import pandas as pd
from db_utils import get_conn
import streamlit as st # Si la función se llama desde Streamlit


def guardar_bases(df_remplazo, df_marco, df_muestra, df_municipios=None, var_upm="UPM"):
    """
    Guarda los DataFrames en la base de datos SQLite.
    Crea las tablas 'reemplazo', 'marco' y 'muestra'.
    """
    try:
        with get_conn() as conn:
            # === 1. Guardar la tabla 'reemplazo' ===
            # Usa el DataFrame df_remplazo completo para la tabla 'reemplazo'
            df_remplazo.to_sql("reemplazo", conn, if_exists="replace", index=False)
            print("Tabla 'reemplazo' guardada exitosamente.")

            # === 2. Guardar la tabla 'marco' ===
            df_marco.to_sql("marco", conn, if_exists="replace", index=False)
            print("Tabla 'marco' guardada exitosamente.")

            # === 3. Guardar la tabla 'muestra' ===
            df_muestra.to_sql("muestra", conn, if_exists="replace", index=False)
            print("Tabla 'muestra' guardada exitosamente.")

            # === 3. Guardar la tabla 'muestra' ===
            if df_municipios is not None:
                 df_municipios.to_sql(
                     name="municipios",
                     con=engine,
                     if_exists="replace",
                     index=False
                 )
            
            # Confirmar los cambios
            conn.commit()
            return True, "Tablas guardadas correctamente en la base de datos."

    except Exception as e:
        # En caso de error, no hacer el commit y mostrar el error
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


def registrar_cambio(nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo):
    with get_conn() as conn:
        conn.execute("INSERT INTO cambios VALUES (?,?,?,?,?,?,?,?)",
            (nombre_completo, cedula, upm_original, upm_reemplazo, de_acuerdo, por_que_no, motivo, datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        conn.commit()

def eliminar_registros_por_rid(rowids):
    with get_conn() as conn:
        conn.executemany("DELETE FROM cambios WHERE rowid = ?", [(rid,) for rid in rowids])
        conn.commit()

def cargar_cambios():
    """
    Retorna un DataFrame con todos los cambios registrados.
    """
    with get_conn() as conn:
        try:
            df = pd.read_sql("SELECT * FROM cambios", conn)
        except:
            df = pd.DataFrame()
    return df

init_sqlite_tables()
