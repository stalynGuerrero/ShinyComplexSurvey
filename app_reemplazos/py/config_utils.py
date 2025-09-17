import yaml, os
from yaml.loader import SafeLoader

CONFIG_FILE = "app_reemplazos/py/config.yaml"

def guardar_config(config_obj):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        yaml.dump(config_obj, f, default_flow_style=False, allow_unicode=True)

def cargar_config():
    if not os.path.exists(CONFIG_FILE):
        base = {
            "credentials": {"usernames": {}},
            "cookie": {"name": "reemplazos_cookie","key": "clave_segura","expiry_days": 30},
            "preauthorized": {"emails": []}
        }
        guardar_config(base)
        return base
    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        cfg = yaml.load(f, Loader=SafeLoader) or {}
        cfg.setdefault("credentials", {}).setdefault("usernames", {})
        return cfg
