import os
import sys
import subprocess
from pathlib import Path

def main():
    print("=" * 60)
    print("  ADiUVA Custom YOLOv8 Transfer Learning & Export Pipeline  ")
    print("=" * 60)

    # 1. Paths configuration
    project_root = Path(__file__).parent.parent.resolve()
    data_yaml = project_root / "dataset" / "data.yaml"
    weights_path = project_root / "yolov8n.pt"

    if not data_yaml.exists():
        print(f"[ERROR] data.yaml not found at: {data_yaml}")
        sys.exit(1)

    if not weights_path.exists():
        print(f"[WARNING] Base weights {weights_path} not found. Ultralytics will download yolov8n.pt automatically.")
        weights_model = "yolov8n.pt"
    else:
        weights_model = str(weights_path)

    # Check dataset image count before starting
    train_img_dir = project_root / "dataset" / "images" / "train"
    train_images = list(train_img_dir.glob("*.[jJ][pP][gG]")) + list(train_img_dir.glob("*.[pP][nN][gG]"))
    print(f"[DATASET] Found {len(train_images)} training images in {train_img_dir}")

    if len(train_images) == 0:
        print("[NOTICE] No images found in dataset/images/train/.")
        print("[NOTICE] Please collect 50-100 real images per class before running training.")
        print("[NOTICE] Training pipeline is fully prepared and ready for data collection!")
        return

    # 2. Import Ultralytics and start training
    from ultralytics import YOLO

    print(f"\n[STEP 1] Loading base YOLOv8n model ({weights_model})...")
    model = YOLO(weights_model)

    print("\n[STEP 2] Starting transfer learning fine-tuning...")
    results = model.train(
        data=str(data_yaml),
        epochs=50,
        imgsz=320,
        batch=16,
        name="adiuva_yolov8n",
        project=str(project_root / "runs"),
        exist_ok=True,
    )

    best_pt = project_root / "runs" / "adiuva_yolov8n" / "weights" / "best.pt"
    print(f"\n[STEP 2 COMPLETE] Best weights saved at: {best_pt}")

    # 3. Export fine-tuned PyTorch weights to ONNX
    print("\n[STEP 3] Exporting fine-tuned model to ONNX format (imgsz=320)...")
    best_model = YOLO(str(best_pt))
    onnx_path = best_model.export(format="onnx", imgsz=320, simplify=True)
    print(f"[ONNX EXPORT] Successfully exported ONNX model to: {onnx_path}")

    # 4. Convert ONNX to Float32 TFLite via onnx2tf
    print("\n[STEP 4] Converting ONNX to Float32 TensorFlow Lite via onnx2tf...")
    output_tflite_dir = project_root / "runs" / "tflite_export"
    os.makedirs(output_tflite_dir, exist_ok=True)

    cmd = [
        sys.executable, "-m", "onnx2tf",
        "-i", str(onnx_path),
        "-o", str(output_tflite_dir),
    ]

    try:
        subprocess.run(cmd, check=True)
        print(f"[TFLITE EXPORT] onnx2tf conversion succeeded! Saved to: {output_tflite_dir}")

        # Find exported tflite model file
        generated_tflites = list(output_tflite_dir.glob("*.tflite"))
        if generated_tflites:
            final_tflite = generated_tflites[0]
            target_asset_tflite = project_root / "assets" / "models" / "yolo" / "yolov8n.tflite"
            print(f"\n[SUCCESS] Generated Float32 TFLite model: {final_tflite}")
            print(f"[NEXT STEP] Copy {final_tflite} to {target_asset_tflite}")
            print(f"[NEXT STEP] Update assets/models/yolo/labels.txt with custom labels (watch, keys, wallet, etc.).")
    except Exception as e:
        print(f"[ERROR] onnx2tf export failed: {e}")

if __name__ == "__main__":
    main()
