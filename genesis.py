import argparse
import csv
from enum import StrEnum
import logging
import os
import string
import sys
from typing import List, Optional, Tuple

import django
from dotenv import load_dotenv
# import psycopg2  # noqa: E402
import pgtoolkit.pgpass as pgt
from termcolor import colored

sys.path.append('../backoffice/')
sys.path.append('backoffice/')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'setup.settings')
django.setup()
from django.contrib.auth.models import Group, Permission, User  # noqa: E402
from django.utils import timezone  # noqa: E402

# TODO implement as pypy package

__author__ = 'jefferson@jeffersoncampos.eti.br'

for denvp in [os.path.join(os.path.dirname(__file__), '../api/.env'), os.path.join(os.path.dirname(__file__), '../backoffice/.env'), os.path.join(os.path.dirname(__file__), '../bot/.env')]:  # noqa: E501
    load_dotenv(denvp)

# query: str
# conn = psycopg2.connect(database=os.getenv('DB_DATABASE'),
#                         user=os.getenv('DB_USER'), password=os.getenv('DB_PASS'),  # noqa: E501
#                         host=os.getenv('DB_HOST'), port=os.getenv('DB_PORT')
#                         )
# cur = conn.cursor()

USER_MANAGEMENT_APP_LABEL: List[str] = [
    'auth',
    'contenttypes',
    'admin'
]


class ForgeUserGroup(StrEnum):
    ADMIN: str = 'ADMINISTRADORES'
    IT_STAFF: str = 'TI'
    OPERATORS: str = 'OPERADORES'
    SYSTEM: str = 'SISTEMA'


def get_random_string(length, stringset=string.ascii_letters):
    return ''.join([stringset[i % len(stringset)] for i in [ord(x) for x in os.urandom(length)]])  # noqa: E501


def create_default_groups(app_label: str) -> None:
    for forge_user_group in ForgeUserGroup:
        group, created = Group.objects.get_or_create(name=forge_user_group.value)  # noqa: E501

        if forge_user_group == ForgeUserGroup.ADMIN:
            perms = Permission.objects.all()
        elif forge_user_group == ForgeUserGroup.IT_STAFF:
            perms = Permission.objects.filter(content_type__app_label__in=USER_MANAGEMENT_APP_LABEL)  # noqa: E501
        elif forge_user_group == ForgeUserGroup.OPERATORS or forge_user_group == ForgeUserGroup.SYSTEM:  # noqa: E501
            perms = Permission.objects.filter(content_type__app_label=app_label)  # noqa: E501

        group.permissions.add(*perms)


def create_users(user_group: str, username: str, first_name: str, last_name: str, email: str, is_superuser: bool = False, is_staff: bool = True, password: Optional[str] = None) -> User:  # noqa: E501
    group = Group.objects.get(name=user_group)
    user, created = User.objects.get_or_create(
        username=username,
        defaults={
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "is_superuser": is_superuser,
            "is_staff": is_staff,
            "is_active": True,
            "date_joined": timezone.now(),
        }
    )
    if password is not None:
        user.set_password(password)
        user.save()

    user.groups.add(group)

    logging.info(f'User {username} ({user_group} :: {group.id=}) created: {created} --> {user.id=}')

    return user


def pgpass_file() -> None:
    print('Executing genesis')
    # with open('.pgpass', 'r') as fo:
    with open(os.path.join(os.path.dirname(__file__), '../.pgpass'), 'r') as fo:  # noqa: E501
        cfg = pgt.parse(fo)
        print(f'{cfg.lines[0]=} --> {cfg.lines[0].hostname=} :: {cfg.lines[0].port=} :: {cfg.lines[0].database=} :: {cfg.lines[0].username=} :: {cfg.lines[0].password=}')  # noqa: E501
        print('---------------------------------------------------------')
        for index, line in enumerate(cfg.lines):
            print(f'{index=} --> {line.hostname=} :: {line.port=} :: {line.database=} :: {line.username=} :: {line.password=}')  # noqa: E501


def get_config_value(*sources: str | None, var_name: str, not_show_debug: Tuple[str] = ('DB_ENGINE', 'DB_SCHEMA')) -> str:  # noqa: E501
    """
    Get config values the follow order: .env (py) > .pgpass > os environment
    """
    invalid_values: Tuple[str] = (None, '', '<OPTIONAL>',)
    value: str = next((s for s in sources if s not in invalid_values), None)

    if var_name not in not_show_debug:
        print(f'{var_name=} {value=} {tuple((s for s in sources if s not in invalid_values))}')  # noqa: E501

    if value is None:
        raise ValueError(f'{var_name} not found (is empty | None)!!')

    return value


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Script to populate initial users for project. Padrão do log é: loglevel = logging.INFO.")  # noqa: E501
    parser.add_argument("-c", "--create", action="append", choices=["all"] + [fug.name.lower() for fug in ForgeUserGroup], help="Choose which group should be created (lower char). DEFAULT: all.")  # noqa: E501
    parser.add_argument("-l", "--log_type", choices=["quiet", "verbose", "normal"], default=["normal"], help="Choose which group should be created. DEFAULT: all.")  # noqa: E501
    args = parser.parse_args()
    if args.create is None or 'all' in args.create:
        args.create = ['all']

    match args.log_type:
        case 'quiet':
            level = logging.WARN
            # logformat = '[%(levelname)s] %(message)s'
            logformat = colored('[%(levelname)s]', 'magenta', attrs=['bold', 'dark']) + ' %(message)s'
        case 'verbose':
            level = logging.DEBUG
            logformat = colored('[%(asctime)s][%(process)d:%(processName)s]', 'green', attrs=['bold', 'dark']) + colored('[%(filename)s#%(funcName)s:%(lineno)d]', 'white', attrs=['bold', 'dark']) + colored('[%(levelname)s]', 'magenta', attrs=['bold', 'dark']) + ' %(message)s '
        case _:                   # elif log_type == 'normal':
            level = logging.INFO
            logformat = colored('[%(asctime)s]', 'green', attrs=['bold', 'dark']) + colored('[%(filename)s:%(lineno)d]', 'white', attrs=['bold', 'dark']) + colored('[%(levelname)s]', 'magenta', attrs=['bold', 'dark']) + ' %(message)s'
            logging.basicConfig(level=level, format=logformat)

    logging.info("# 0 - CREATE GROUPS AND PERMISSIONS...")
    create_default_groups(app_label=os.getenv('FORGE_SYSTEM_ACRONYM'))

    logging.info(f'# 1 - CREATING USERS... choices: {args.create}')
    if any([opt in args.create for opt in ['all', ForgeUserGroup.ADMIN.name.lower()]]):  # noqa: E501
        logging.info('## 1.0 - Admin')
        create_users(user_group=ForgeUserGroup.ADMIN.value, username=os.getenv('DJANGO_SUPERUSER_USERNAME'), first_name=os.getenv('DJANGO_SUPERUSER_FIRSTNAME'), last_name=os.getenv('DJANGO_SUPERUSER_LASTNAME'), email=os.getenv('DJANGO_SUPERUSER_EMAIL'), is_superuser=True, is_staff=True, password=os.getenv('DJANGO_SUPERUSER_PASSWORD'))  # noqa: E501

    if any([opt in args.create for opt in ['all', ForgeUserGroup.SYSTEM.name.lower()]]):  # noqa: E501
        logging.info('## 1.1 - System')
        create_users(user_group=ForgeUserGroup.SYSTEM.value, username='api_auth', first_name='API', last_name='Authentication', email=f'api@{os.getenv("FORGE_SYSTEM_BASE_DNS")}.{os.getenv("FORGE_ORGANIZATION_BASEDNS")}', is_superuser=False, is_staff=False, password=os.getenv('API_AUTHORIZATION_TOKEN'))  # noqa: E501

    if any([opt in args.create for opt in ['all', ForgeUserGroup.IT_STAFF.name.lower()]]):  # noqa: E501
        logging.info('## 1.2 - IT')
        for index, username in enumerate(str(os.getenv('TARGET_SERVER_DBAS')).split(',')):
            logging.info(f'### 1.2.{index:02} - DBA {username}')
            create_users(user_group=ForgeUserGroup.IT_STAFF.value, username=username, first_name=username, last_name='IT STAFF', email=f'{username}@{os.getenv("FORGE_SYSTEM_BASE_DNS")}.{os.getenv("FORGE_ORGANIZATION_BASEDNS")}', is_superuser=False, is_staff=True)  # noqa: E501

    logging.info('## 1.3 - OPERATORS & CUSTOM USERS (ANY OTHER GROUPS)')
    # FIXME store it in .credentials/secure/user_seeds.csv - ALSO add it to samples  # noqa: E501
    with open(f'{os.getenv("APP_PATH_ETC")}/.user_seeds.csv.{os.getenv("TARGET_ENV")}') as users:
        for index, user in enumerate(csv.DictReader(users, delimiter=";")):
            allowed: bool = any([group_target in args.create for group_target in ['all', user['group_name'].lower()]])
            logging.info(f'### 1.3.{index:05} ({user["group_name"]}) {user["username"]} is allowed to create? {allowed}')  # noqa: E501
            if not allowed:
                continue
            create_users(user_group=ForgeUserGroup[user['group_name'].upper()].value, username=user['username'], first_name=user['first_name'], last_name=user['last_name'], email=user['email'], is_superuser=True if user['is_superuser'].upper() in ['TRUE', 1, 'T'] else False, is_staff=True if user['is_staff'].upper() in ['TRUE', 1, 'T'] else False, password=None if user['password'].upper() in ['<NULL>', 'NULL', '<NONE>', 'NONE', '<NIL>', 'NIL'] else user['password'])  # noqa: E501
            logging.debug(f'### 1.3.{index:05} ({user["group_name"]}) {user["username"]} CREATED!!')  # noqa: E501
