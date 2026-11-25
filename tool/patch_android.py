#!/usr/bin/env python3
"""Menyiapkan proyek Android Flutter lalu menambal tanda tangan rilis, label,
ikon, dan warna splash.

Dijalankan di CI setelah `flutter pub get`. Hasilnya folder `android/` yang
siap dibangun dengan keystore dari environment:

    RY_KEYSTORE   path absolut ke keystore (PKCS12)
    RY_STOREPASS  password keystore
    RY_KEYALIAS   alias kunci
    RY_KEYPASS    password kunci (opsional, default sama)

Skrip ini sengaja berhenti dengan galat kalau template Flutter berubah, supaya
APK tidak diam-diam dibangun tanpa tanda tangan rilis.
"""

from __future__ import annotations

import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"

APPLICATION_ID = "app.rymoney"
APP_LABEL = "Ry-Money"


def fail(message: str) -> "NoReturn":
    print(f"GAGAL: {message}", file=sys.stderr)
    sys.exit(1)


def run(command: list[str], cwd: Path) -> None:
    print("+", " ".join(command))
    subprocess.run(command, cwd=str(cwd), check=True)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


# ---------------------------------------------------------------- ikon PNG


def png_chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def make_icon_png(size: int) -> bytes:
    """Buku kas: empat garis di atas tinta hangat. Digambar tanpa Pillow."""
    ink = (10, 11, 8, 255)
    acid = (200, 247, 81, 255)
    lime = (159, 191, 72, 255)
    olive = (111, 124, 62, 255)

    scale = size / 108.0
    bars = [
        (31, 33, 77, 43, acid),
        (31, 48, 59, 58, acid),
        (31, 63, 68, 73, lime),
        (31, 78, 52, 88, olive),
    ]
    rows = bytearray()
    for y in range(size):
        rows.append(0)
        for x in range(size):
            color = ink
            for x0, y0, x1, y1, fill in bars:
                if x0 * scale <= x < x1 * scale and y0 * scale <= y < y1 * scale:
                    color = fill
                    break
            rows.extend(color)
    header = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", header)
        + png_chunk(b"IDAT", zlib.compress(bytes(rows), 9))
        + png_chunk(b"IEND", b"")
    )


def write_icons() -> None:
    res = ANDROID / "app" / "src" / "main" / "res"
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in sizes.items():
        target = res / folder / "ic_launcher.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(make_icon_png(px))
        print(f"  ikon {target.relative_to(ROOT)} ({px}px)")

    background = (res / "values" / "colors.xml")
    if background.exists():
        text = background.read_text(encoding="utf-8")
        if "ic_launcher_background" not in text:
            text = text.replace(
                "</resources>",
                "    <color name=\"ic_launcher_background\">#0A0B08</color>\n</resources>",
            )
            background.write_text(text, encoding="utf-8")
    else:
        write(
            background,
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<resources>\n"
            '    <color name="ic_launcher_background">#0A0B08</color>\n'
            "</resources>\n",
        )

    write(
        res / "drawable" / "ic_launcher_foreground.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#C8F751" android:pathData="M31,33h46v10h-46z" />
    <path android:fillColor="#C8F751" android:pathData="M31,48h28v10h-28z" />
    <path android:fillColor="#9FBF48" android:pathData="M31,63h37v10h-37z" />
    <path android:fillColor="#6F7C3E" android:pathData="M31,78h21v10h-21z" />
</vector>
""",
    )
    write(
        res / "mipmap-anydpi-v26" / "ic_launcher.xml",
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
""",
    )


def patch_splash() -> None:
    res = ANDROID / "app" / "src" / "main" / "res"
    for folder in ("drawable", "drawable-v21"):
        target = res / folder / "launch_background.xml"
        if not target.exists():
            continue
        write(
            target,
            """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/ic_launcher_background" />
</layer-list>
""",
        )
        print(f"  splash {target.relative_to(ROOT)}")


# ---------------------------------------------------------------- gradle


def patch_gradle() -> None:
    gradle = ANDROID / "app" / "build.gradle.kts"
    if not gradle.exists():
        gradle = ANDROID / "app" / "build.gradle"
    if not gradle.exists():
        fail("app/build.gradle(.kts) tidak ditemukan")

    text = gradle.read_text(encoding="utf-8")
    if APPLICATION_ID not in text:
        fail(
            f'applicationId "{APPLICATION_ID}" tidak ada di {gradle.name}; '
            "template Flutter berubah."
        )

    if "RY_KEYSTORE" in text:
        print("  gradle sudah ditambal, dilewati")
        return

    kotlin = gradle.suffix == ".kts"
    signing_block = """
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("RY_KEYSTORE"))
            storePassword = System.getenv("RY_STOREPASS")
            keyAlias = System.getenv("RY_KEYALIAS")
            keyPassword = System.getenv("RY_KEYPASS") ?: System.getenv("RY_STOREPASS")
            storeType = "PKCS12"
        }
    }
""" if kotlin else """
    signingConfigs {
        release {
            storeFile file(System.getenv("RY_KEYSTORE"))
            storePassword System.getenv("RY_STOREPASS")
            keyAlias System.getenv("RY_KEYALIAS")
            keyPassword System.getenv("RY_KEYPASS") ?: System.getenv("RY_STOREPASS")
            storeType 'PKCS12'
        }
    }
"""

    marker = "    buildTypes {"
    if marker not in text:
        fail(f"penanda 'buildTypes' tidak ditemukan di {gradle.name}")
    text = text.replace(marker, signing_block + "\n" + marker, 1)

    debug_line = None
    for line in text.splitlines():
        if "signingConfigs.getByName(\"debug\")" in line:
            debug_line = line
            break
        if "signingConfig signingConfigs.debug" in line:
            debug_line = line
            break
    if debug_line is None:
        fail(f"baris signingConfig debug tidak ditemukan di {gradle.name}")

    if "getByName" in debug_line:
        text = text.replace(debug_line, debug_line.replace("debug", "release"), 1)
    else:
        text = text.replace(debug_line, debug_line.replace("debug", "release"), 1)

    gradle.write_text(text, encoding="utf-8")
    print(f"  gradle ditambal ({gradle.name})")


def patch_manifest() -> None:
    manifest = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        fail("AndroidManifest.xml tidak ditemukan")
    text = manifest.read_text(encoding="utf-8")
    if 'android:label="rymoney"' in text:
        text = text.replace('android:label="rymoney"', f'android:label="{APP_LABEL}"')
    elif f'android:label="{APP_LABEL}"' not in text:
        fail("label aplikasi tidak dikenali di AndroidManifest.xml")
    manifest.write_text(text, encoding="utf-8")
    print("  label aplikasi:", APP_LABEL)


def main() -> None:
    for name in ("RY_KEYSTORE", "RY_STOREPASS", "RY_KEYALIAS"):
        if not os.environ.get(name):
            fail(
                f"environment {name} kosong. APK rilis harus ditandatangani "
                "kunci yang sama dengan versi sebelumnya."
            )
    if not Path(os.environ["RY_KEYSTORE"]).is_file():
        fail(f"keystore tidak ditemukan: {os.environ['RY_KEYSTORE']}")

    shell = Path(tempfile.gettempdir()) / "rymoney-shell"
    if shell.exists():
        shutil.rmtree(shell)

    run(
        [
            "flutter",
            "create",
            "--platforms=android",
            "--org",
            "app",
            "--project-name",
            "rymoney",
            str(shell),
        ],
        ROOT,
    )

    if ANDROID.exists():
        shutil.rmtree(ANDROID)
    shutil.copytree(shell / "android", ANDROID)
    print(f"  android/ disalin dari template ({shell})")

    patch_gradle()
    patch_manifest()
    write_icons()
    patch_splash()

    print("Android siap dibangun.")


if __name__ == "__main__":
    main()
