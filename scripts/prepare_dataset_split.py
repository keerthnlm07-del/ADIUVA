import os
import shutil
import random
from pathlib import Path

def main():
    print("=" * 60)
    print("  ADiUVA Custom Dataset Train/Val Split Helper  ")
    print("=" * 60)

    project_root = Path(__file__).parent.parent.resolve()
    dataset_dir = project_root / "dataset"
    raw_dir = dataset_dir / "raw_annotations"

    if not raw_dir.exists():
        print(f"[NOTICE] Created raw annotations directory: {raw_dir}")
        print("[NOTICE] Save your raw images (.jpg/.png) and YOLO .txt label files into dataset/raw_annotations/")
        os.makedirs(raw_dir, exist_ok=True)
        return

    # Find matching image & txt pairs
    images = list(raw_dir.glob("*.jpg")) + list(raw_dir.glob("*.png")) + list(raw_dir.glob("*.jpeg"))
    pairs = []

    for img_path in images:
        txt_path = img_path.with_suffix(".txt")
        if txt_path.exists():
            pairs.append((img_path, txt_path))

    print(f"[FOUND] Found {len(pairs)} matched image + YOLO txt label pairs in {raw_dir}")

    if len(pairs) == 0:
        print("[NOTICE] No matched pairs found yet. Place images and corresponding .txt label files in dataset/raw_annotations/")
        return

    # Shuffle seed for reproducible split
    random.seed(42)
    random.shuffle(pairs)

    val_ratio = 0.2
    val_count = max(1, int(len(pairs) * val_ratio))
    val_pairs = pairs[:val_count]
    train_pairs = pairs[val_count:]

    # Target subdirectories
    img_train = dataset_dir / "images" / "train"
    img_val = dataset_dir / "images" / "val"
    lbl_train = dataset_dir / "labels" / "train"
    lbl_val = dataset_dir / "labels" / "val"

    for d in [img_train, img_val, lbl_train, lbl_val]:
        os.makedirs(d, exist_ok=True)

    print(f"\n[SPLIT] Copying {len(train_pairs)} pairs to TRAIN and {len(val_pairs)} pairs to VAL...")

    for img_path, txt_path in train_pairs:
        shutil.copy2(img_path, img_train / img_path.name)
        shutil.copy2(txt_path, lbl_train / txt_path.name)

    for img_path, txt_path in val_pairs:
        shutil.copy2(img_path, img_val / img_path.name)
        shutil.copy2(txt_path, lbl_val / txt_path.name)

    print(f"[SUCCESS] Dataset split complete!")
    print(f"  Train: {len(train_pairs)} images -> {img_train}")
    print(f"  Val:   {len(val_pairs)} images -> {img_val}")

if __name__ == "__main__":
    main()
