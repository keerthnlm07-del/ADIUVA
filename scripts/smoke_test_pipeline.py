import os
import sys
import subprocess
from pathlib import Path

def run_smoke_test():
    print("=" * 60)
    print("  ADiUVA YOLOv8 Transfer-Learning & TFLite Export Smoke Test  ")
    print("=" * 60)

    project_root = Path(__file__).parent.parent.resolve()
    data_yaml = project_root / "dataset" / "data.yaml"
    weights_path = project_root / "yolov8n.pt"

    if not data_yaml.exists():
        print(f"[ERROR] data.yaml not found at: {data_yaml}")
        sys.exit(1)

    print("\n[STEP 1] Testing Ultralytics YOLO Training (1 Epoch Smoke Test)...")
    from ultralytics import YOLO

    model = YOLO(str(weights_path) if weights_path.exists() else "yolov8n.pt")

    smoke_run_dir = project_root / "runs" / "smoke_test"
    results = model.train(
        data=str(data_yaml),
        epochs=1,
        imgsz=320,
        batch=2,
        name="smoke_test",
        project=str(project_root / "runs"),
        exist_ok=True,
        workers=0, # Avoid multi-process worker issues on Windows
    )

    best_pt = project_root / "runs" / "smoke_test" / "weights" / "best.pt"
    if not best_pt.exists():
        # Fall back to last.pt if best.pt wasn't saved in 1 epoch
        best_pt = project_root / "runs" / "smoke_test" / "weights" / "last.pt"

    print(f"[SUCCESS] Training test passed! Generated PyTorch weights at: {best_pt}")

    # STEP 2: ONNX Export
    print("\n[STEP 2] Testing ONNX Export at 320x320...")
    best_model = YOLO(str(best_pt))
    onnx_path = best_model.export(format="onnx", imgsz=320, simplify=True)
    print(f"[SUCCESS] ONNX export passed! Generated ONNX model at: {onnx_path}")

    # Inspect ONNX using onnx module
    try:
        import onnx
        onnx_model = onnx.load(onnx_path)
        onnx.checker.check_model(onnx_model)
        inp = onnx_model.graph.input[0]
        out = onnx_model.graph.output[0]
        inp_shape = [d.dim_value for d in inp.type.tensor_type.shape.dim]
        out_shape = [d.dim_value for d in out.type.tensor_type.shape.dim]
        print(f"[ONNX INSPECTION] Input: {inp.name}, Shape: {inp_shape}")
        print(f"[ONNX INSPECTION] Output: {out.name}, Shape: {out_shape}")
    except Exception as e:
        print(f"[ONNX INSPECTION WARN] {e}")

    # STEP 3: ONNX-to-TFLite Conversion via onnx2tf
    print("\n[STEP 3] Testing ONNX-to-Float32 TFLite Conversion via onnx2tf...")
    output_tflite_dir = project_root / "runs" / "smoke_tflite"
    os.makedirs(output_tflite_dir, exist_ok=True)

    cmd = [
        sys.executable, "-m", "onnx2tf",
        "-i", str(onnx_path),
        "-o", str(output_tflite_dir),
    ]

    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[TFLITE EXPORT STDOUT] {res.stdout[-1000:]}")
        print(f"[TFLITE EXPORT STDERR] {res.stderr[-1000:]}")
        print("[ERROR] onnx2tf failed!")
        sys.exit(1)

    print("[SUCCESS] onnx2tf conversion passed!")

    # STEP 4: Inspect Final TFLite Tensors
    generated_tflites = list(output_tflite_dir.glob("*.tflite"))
    if not generated_tflites:
        print(f"[ERROR] No .tflite files found in {output_tflite_dir}")
        sys.exit(1)

    tflite_file = generated_tflites[0]
    print(f"\n[STEP 4] Inspecting Final TFLite Model: {tflite_file}")
    file_size = os.path.getsize(tflite_file)
    print(f"[TFLITE FILE] Size: {file_size} bytes ({file_size / (1024*1024):.2f} MB)")

    try:
        import tflite_flutter as tfl
        interp = tfl.Interpreter.fromFile(str(tflite_file))
        inp = interp.getInputTensor(0)
        out = interp.getOutputTensor(0)
        print(f"[TFLITE TENSORS] Input Name: {inp.name}, Shape: {inp.shape}, Type: {inp.type}")
        print(f"[TFLITE TENSORS] Output Name: {out.name}, Shape: {out.shape}, Type: {out.type}")
        interp.close()
    except Exception as e:
        print(f"[TFLITE INSPECTION INFO] {e}")

    print("\n" + "=" * 60)
    print("  ALL SMOKE TEST PIPELINE STAGES PASSED SUCCESSFULLY!  ")
    print("=" * 60)

if __name__ == "__main__":
    run_smoke_test()
