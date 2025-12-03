import pandas as pd
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parents[1]
DATA_PATH = BASE_DIR / "data" / "telco_customer_churn.csv"
OUTPUT_DIR = BASE_DIR / "outputs"
OUTPUT_DIR.mkdir(exist_ok=True)

CLEANED_PATH = OUTPUT_DIR / "telco_cleaned.csv"
REPORT_PATH = OUTPUT_DIR / "data_quality_report.md"

def load_data(path: Path) -> pd.DataFrame:
    return pd.read_csv(path)

def standardise_columns(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
    )
    return df

def convert_numeric(df: pd.DataFrame) -> pd.DataFrame:
    if "totalcharges" in df.columns:
        df["totalcharges"] = (
            df["totalcharges"]
            .replace(" ", pd.NA)
            .astype("float64")
        )
    return df

def handle_missing(df: pd.DataFrame) -> pd.DataFrame:
    numeric_cols = df.select_dtypes(include=["number"]).columns
    cat_cols = df.select_dtypes(include=["object", "category"]).columns

    for col in numeric_cols:
        df[col] = df[col].fillna(df[col].median())

    for col in cat_cols:
        df[col] = df[col].fillna(df[col].mode()[0])

    return df

def normalise_categories(df: pd.DataFrame) -> pd.DataFrame:
    replace_map = {
        "No internet service": "No",
        "No phone service": "No"
    }
    obj_cols = df.select_dtypes(include=["object", "category"]).columns
    for col in obj_cols:
        df[col] = df[col].replace(replace_map)
    return df

def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    return df.drop_duplicates()

def generate_report(raw: pd.DataFrame, clean: pd.DataFrame, path: Path) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write("# Telco Data Quality Report\n\n")
        f.write(f"- Raw shape: {raw.shape}\n")
        f.write(f"- Cleaned shape: {clean.shape}\n\n")
        f.write("## Missing values (raw)\n\n")
        f.write(raw.isna().sum().to_string())
        f.write("\n\n## Missing values (cleaned)\n\n")
        f.write(clean.isna().sum().to_string())
        f.write("\n\n## Dtypes (cleaned)\n\n")
        f.write(clean.dtypes.to_string())
        f.write("\n")

def main():
    raw = load_data(DATA_PATH)
    df = raw.copy()

    df = standardise_columns(df)
    df = convert_numeric(df)
    df = handle_missing(df)
    df = normalise_categories(df)
    df = remove_duplicates(df)

    CLEANED_PATH.parent.mkdir(exist_ok=True)
    df.to_csv(CLEANED_PATH, index=False)
    generate_report(raw, df, REPORT_PATH)

    print(f"Saved cleaned data to {CLEANED_PATH}")
    print(f"Saved report to {REPORT_PATH}")

if __name__ == "__main__":
    main()
