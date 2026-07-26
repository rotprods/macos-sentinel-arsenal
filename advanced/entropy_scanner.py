#!/usr/bin/env python3
"""
🛡️ Shannon Entropy Gatekeeper
Calcula la entropía de Shannon de un archivo para detectar código ofuscado o payloads cifrados.
- H < 6.0: Probablemente código limpio.
- 6.0 < H < 6.5: Código minificado o comprimido.
- H > 6.5: Peligro de ofuscación extrema / Base64 Payload.
"""

import sys
import math
import os
import json
import logging
from pathlib import Path
from collections import Counter

# Configurar logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

def calculate_shannon_entropy(file_path: str) -> float:
    """Calcula la Entropía de Shannon de un archivo a nivel de byte."""
    try:
        with open(file_path, 'rb') as f:
            data = f.read()
            
        if not data:
            return 0.0
            
        # Calcular frecuencias de bytes (0-255)
        byte_counts = Counter(data)
        file_length = len(data)
        
        # Fórmula de Shannon: H(X) = -sum(P(x_i) * log2(P(x_i)))
        entropy = 0.0
        for count in byte_counts.values():
            probability = count / file_length
            entropy -= probability * math.log2(probability)
            
        return entropy
    except Exception as e:
        logging.error(f"Error calculando entropía para {file_path}: {str(e)}")
        return -1.0

def analyze_directory(dir_path: str) -> dict:
    """Analiza recursivamente un directorio (ej. paquete NPM desempaquetado)."""
    results = {
        "target": dir_path,
        "max_entropy": 0.0,
        "files_scanned": 0,
        "flagged_files": [],
        "verdict": "SAFE"
    }
    
    path = Path(dir_path)
    if not path.exists():
        logging.error(f"La ruta no existe: {dir_path}")
        return results
        
    for file_path in path.rglob('*'):
        if file_path.is_file() and not file_path.name.startswith('.'):
            # Filtrar binarios obvios permitidos (ej. imágenes, aunque NPM no debería tener muchas)
            if file_path.suffix.lower() in ['.png', '.jpg', '.jpeg', '.gif', '.webp']:
                continue
                
            entropy = calculate_shannon_entropy(str(file_path))
            results["files_scanned"] += 1
            
            if entropy > results["max_entropy"]:
                results["max_entropy"] = entropy
                
            if entropy > 6.5:
                results["flagged_files"].append({
                    "file": str(file_path.relative_to(path)),
                    "entropy": round(entropy, 3),
                    "risk": "CRITICAL"
                })
            elif entropy > 6.0:
                results["flagged_files"].append({
                    "file": str(file_path.relative_to(path)),
                    "entropy": round(entropy, 3),
                    "risk": "WARNING"
                })
                
    # Veredicto final
    if results["max_entropy"] > 6.5:
        results["verdict"] = "BLOCKED_OBFUSCATION_DETECTED"
    elif results["max_entropy"] > 6.0:
        results["verdict"] = "WARNING_MINIFIED_CODE"
        
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 entropy_scanner.py <ruta_archivo_o_directorio>")
        sys.exit(1)
        
    target_path = sys.argv[1]
    
    if os.path.isdir(target_path):
        results = analyze_directory(target_path)
    else:
        entropy = calculate_shannon_entropy(target_path)
        verdict = "SAFE"
        if entropy > 6.5:
            verdict = "BLOCKED_OBFUSCATION_DETECTED"
        elif entropy > 6.0:
            verdict = "WARNING_MINIFIED_CODE"
            
        results = {
            "target": target_path,
            "max_entropy": round(entropy, 3),
            "files_scanned": 1,
            "verdict": verdict,
            "flagged_files": [{"file": os.path.basename(target_path), "entropy": round(entropy, 3), "risk": verdict}] if entropy > 6.0 else []
        }
        
    print(json.dumps(results, indent=2))
    
    # Exit con error si hay bloqueo para que el hook ZSH aborte la instalación
    if results["verdict"] == "BLOCKED_OBFUSCATION_DETECTED":
        sys.exit(2)
    sys.exit(0)
