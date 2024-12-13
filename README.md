
<h1 align="center">DATA SWEEP: CSV Dataset Cleaning App</h1>

###### 📢 *When you first open the app, there could be a slight delay in deleting columns and other processes due to downtime when the service is not in use (hosted on Render). Thanks for your patience!*
If you're interested, you can access the backend code [here](https://github.com/VivieneGarcia/Data-Sweep-Server). Please note that it's open-source and not designed with advanced security features.


## ⭐ About
Data Sweep is a mobile app designed to help users efficiently clean and preprocess their CSV data, streamlining the process of handling and analyzing datasets with ease.

## 💫 Features
1. **Upload CSV Files** - Provide a platform where users can upload CSV files for data cleaning.

2. **Column Deletion and Issue Resolution** - Perform essential data cleaning tasks such as deleting unnecessary columns and resolving common data issues.

3. **Data Classification** - Classify data types into numerical, categorical, or date formats, and handle invalid or missing values by choosing to replace or delete them.

4. **Outlier Handling and Normalization** - Implement tools for detecting and handling outliers, as well as normalizing and standardizing numerical data for better analysis.

5. **Basic Data Visualization** - Enable basic data visualization to provide insights into the dataset, helping users make informed decisions.

## ✅ Prerequisites
- **Flutter SDK** installed on your machine.
- **Python (Pandas)** for preprocessing (integrated into the app).
- **A supported mobile device** or simulator to run the app.

## ⚙️ Setup
1. Clone or download the repository into your local environment.

    ```bash
    git clone https://github.com/AcePenaflorida/Data-Sweep.git
    ```

2. Install the necessary dependencies for the **Python backend** and **Flutter frontend**.

    - For **Python**, navigate to the backend folder and install dependencies:

        ```bash
        pip install -r requirements.txt
        ```

    - For **Flutter**, navigate to the `flutter_app/` folder (or your Flutter app folder) and install dependencies:

        ```bash
        flutter pub get
        ```

3. Run the **Python Backend** (`app.py`):
    - By default, the app uses the hosted URL (https://data-sweep-server.onrender.com/). If you want to run the backend locally, follow these steps:

    - Navigate to the folder where `app.py` is located.
    - Start the Python server and input the desired **base URL** or **IP address** when prompted:

        ```bash
        python app.py
        ```

    - Enter your choice for the **base URL**:
        - Use a local IP address found in the terminal when you run the python code(e.g., `http://192.168.1.x:5000`)
        - Or use the defualt hosted URL (e.g., `https://data-sweep-server.onrender.com/`)

    You can find the full server code in the [Data-Sweep-Server repository](https://github.com/VivieneGarcia/Data-Sweep-Server).

5. Run the **Flutter Frontend** on a mobile device or simulator:


    ```bash
    flutter run
    ```
6. Launch the app and begin cleaning your CSV datasets with ease!


## 🔧 Built With
* [Flutter](https://flutter.dev/) - Mobile App Framework
* [Python (Pandas)](https://pandas.pydata.org/) - Data Preprocessing
* [CSV](https://www.ietf.org/rfc/rfc4180.txt) - Data Format

## 👥 Members

* [Viviene](https://github.com/VivieneGarcia) 
* [Rain Lyra](https://github.com/rnlyra)
* [Paul](https://github.com/PaulVincent-Calvo) 
* [Ace](https://github.com/AcePenaflorida)


## 🌟Acknowledgments
* Ma'am Lysa Tolentino - App Dev Prof
