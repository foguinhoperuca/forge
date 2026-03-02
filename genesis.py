from enum import StrEnum
import os
import string
import sys
from typing import List, Optional

import django
from dotenv import load_dotenv
# import psycopg2  # noqa: E402


sys.path.append('../backoffice/')
sys.path.append('backoffice/')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'setup.settings')
django.setup()
from django.contrib.auth.models import Group, Permission, User  # noqa: E402
from django.utils import timezone  # noqa: E402

# TODO implement as pypy package

__author__ = 'jecampos@sorocaba.sp.gov.br'

dotenv_path = os.path.join(os.path.dirname(__file__), '../backoffice/.env')
load_dotenv(dotenv_path)

# query: str
# conn = psycopg2.connect(database=os.getenv('DB_DATABASE'),
#                         user=os.getenv('DB_USER'), password=os.getenv('DB_PASS'),
#                         host=os.getenv('DB_HOST'), port=os.getenv('DB_PORT')
#                         )
# cur = conn.cursor()

USER_MANAGEMENT_APP_LABEL: List[str] = [
    'auth',
    'contenttypes',
    'admin'
]


class ForgeUserGroup(StrEnum):
    ADMIN: str = 'ADMIN'
    IT_STAFF: str = 'TI'
    OPERATOR: str = 'OPERADORES'
    SYSTEM: str = 'SISTEMA'


def get_random_string(length, stringset=string.ascii_letters):
    return ''.join([stringset[i % len(stringset)] for i in [ord(x) for x in os.urandom(length)]])


def create_default_groups(app_label: str) -> None:
    for forge_user_group in ForgeUserGroup:
        group, created = Group.objects.get_or_create(name=forge_user_group.value)

        if forge_user_group == ForgeUserGroup.ADMIN:
            perms = Permission.objects.all()
        elif forge_user_group == ForgeUserGroup.IT_STAFF:
            perms = Permission.objects.filter(content_type__app_label__in=USER_MANAGEMENT_APP_LABEL)
        elif forge_user_group == ForgeUserGroup.OPERATOR or forge_user_group == ForgeUserGroup.SYSTEM:
            perms = Permission.objects.filter(content_type__app_label=app_label)

        group.permissions.add(*perms)


def create_users(user_group: str, username: str, first_name: str, last_name: str, email: str, is_superuser: bool = False, is_staff: bool = True, password: Optional[str] = None) -> User:
    new_user: User
    db_user = User.objects.filter(username__contains=username)
    if len(db_user) == 0:
        new_user = User.objects.create(
            username=username,
            first_name=first_name,
            last_name=last_name,
            email=email,
            is_superuser=is_superuser,
            is_staff=is_staff,
            is_active=True,
            date_joined=timezone.now()
        )
        if password is not None:
            new_user.set_password(password)

        new_user.save()
    else:
        new_user = db_user[0]

    group = Group.objects.get(name=user_group)
    group.user_set.add(new_user)

    return new_user


# FIXME implement default creation of group and users here
def forge_create_default_users_groups(create_system_user: bool = False) -> None:
    create_default_groups(app_label='')

    # Minimum for groups: [ADMIN | IT | SYSTEM]
    create_users(user_group=ForgeUserGroup.ADMIN.value, username='admin', first_name='Administrador', last_name='IT FORGE', email='admin@forge.tld', is_superuser=True, is_staff=True, password=os.getenv('DJANGO_SUPERUSER_PASSWORD'))
    if create_system_user:
        create_users(user_group=ForgeUserGroup.SYSTEM.value, username='api_auth',
                     first_name='API',
                     last_name='AUTHENTICATION',
                     email=f'api@{os.getenv("FORGE_SYSTEM_BASE_DNS")}',
                     is_superuser=False,
                     is_staff=False,
                     password=os.getenv('API_AUTHORIZATION_TOKEN'))

    # TODO implement user as IT Staff from os.getenv('TARGET_SERVER_DBAS')
    for username in str(os.getenv('TARGET_SERVER_DBAS')).split(','):
        create_users(user_group=ForgeUserGroup.IT_STAFF.value, username=username, first_name=username, last_name='IT STAFF', email=f'{username}@{os.getenv("FORGE_SYSTEM_BASE_DNS")}', is_superuser=False, is_staff=True)
