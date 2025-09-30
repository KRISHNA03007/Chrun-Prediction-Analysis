import os
import pandas as pd

def load_data(filename: str):
    try:
        # Go 2 levels up from src/data_ingestion/ → project root
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))
        file_path = os.path.join(project_root, "data", "raw", filename)

        # Try reading CSV
        df = pd.read_csv(file_path)
        print(f"Successfully loaded: {file_path}")
        return df

    except FileNotFoundError:
        print(f"File not found: {filename}. Check if it exists in data/raw/")
        return None

    except Exception as e:
        print(f"Error while loading file: {e}")
        return None


if __name__ == "__main__":
    df = load_data("Churn_Modelling.csv")  
    if df is not None:
        print("Data loaded successfully")
