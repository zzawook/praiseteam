"""Checks shared by local Android and Codemagic iOS release builds."""
import base64
import json
from urllib.parse import urlparse

CLIENT_FIELDS = {
    'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'GOOGLE_WEB_CLIENT_ID',
    'GOOGLE_IOS_CLIENT_ID', 'WEB_APP_URL', 'WEB_PUSH_KEY', 'DEV_LOGIN',
    'DEMO_MODE', 'APPLE_SIGN_IN_ENABLED',
}


def enabled(value):
    return str(value).lower() == 'true'


def validate(values, *, ios=False):
    if not isinstance(values, dict):
        raise ValueError('Release settings must be a JSON object.')
    if set(values) - CLIENT_FIELDS:
        raise ValueError('Release JSON contains fields that do not belong in the public client.')
    if any(enabled(values.get(flag, False)) for flag in ['DEV_LOGIN', 'DEMO_MODE']):
        raise ValueError('Development login and sample mode must be disabled in store builds.')
    url = urlparse(values.get('SUPABASE_URL', ''))
    if url.scheme != 'https' or not url.hostname or url.hostname in ['localhost','127.0.0.1','10.0.2.2']:
        raise ValueError('Store builds require the hosted HTTPS backend.')
    key = values.get('SUPABASE_PUBLISHABLE_KEY', '')
    if not isinstance(key, str) or key.startswith('sb_secret_') or not key:
        raise ValueError('Only a publishable key belongs in the app.')
    if key.count('.') == 2:
        payload = key.split('.')[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
        if claims.get('role') != 'anon':
            raise ValueError('A privileged backend key must never be embedded in the app.')
    elif not key.startswith('sb_publishable_'):
        raise ValueError('Unrecognized publishable key format.')
    if not values.get('GOOGLE_WEB_CLIENT_ID', '').endswith('.apps.googleusercontent.com'):
        raise ValueError('Google server client ID is missing.')
    if ios and not enabled(values.get('APPLE_SIGN_IN_ENABLED', False)):
        raise ValueError('Configure the Apple provider and revocation worker, then enable Apple sign-in before an iOS store build.')
    result = dict(values)
    for flag in ['DEV_LOGIN', 'DEMO_MODE', 'APPLE_SIGN_IN_ENABLED']:
        result[flag] = enabled(values.get(flag, False))
    return result
