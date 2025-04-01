#IMPORTS
''''
import pandas as pd
import numpy as np
import json
from sklearn.cluster import KMeans, AgglomerativeClustering, DBSCAN
from sklearn.manifold import TSNE
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import seaborn as sns
import tensorflow as tf
from tensorflow.keras.layers import Input, Dense
from tensorflow.keras.models import Model
from google.cloud import storage
import folium
from folium.plugins import HeatMap
#DO KMEANS no time
from sklearn.cluster import KMeans
#Giving out cluster graph for total
from sklearn.impute import SimpleImputer
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import numpy as np
import os
import shutil
import gzip
#DO KMEANS ON Epoch
from sklearn.cluster import KMeans
#Giving out cluster graph for total
from sklearn.impute import SimpleImputer
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import numpy as np
#DO KMEANS ON Miniute of day
from sklearn.cluster import KMeans
#Giving out cluster graph for total
from sklearn.impute import SimpleImputer
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import numpy as np
from sklearn.preprocessing import StandardScaler
#DO KMEANS ON DAY OF WEEK
from sklearn.cluster import KMeans
#Giving out cluster graph for total
from sklearn.impute import SimpleImputer
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import numpy as np
'''

import os

print("DONE IMPORTS")

#CLEAR ALL FILES // from past runs

decompressed = 'json/'
# Check if the directory exists, and if it does, remove it along with all its contents // this fixed big provlem with having .zips inside them
if os.path.exists(decompressed):
    shutil.rmtree(decompressed)

local = 'local/'
# Check if the directory exists, and if it does, remove it along with all its contents // this fixed big provlem with having .zips inside them
if os.path.exists(local):
    shutil.rmtree(local)

sample_data = 'sample_data/'
# Check if the directory exists, and if it does, remove it along with all its contents // this fixed big provlem with having .zips inside them
if os.path.exists(sample_data):
    shutil.rmtree(sample_data)

zip = 'zip/'
# Check if the directory exists, and if it does, remove it along with all its contents // this fixed big provlem with having .zips inside them
if os.path.exists(zip):
    shutil.rmtree(zip)

download = 'download/'
# Check if the directory exists, and if it does, remove it along with all its contents // this fixed big provlem with having .zips inside them
if os.path.exists(download):
    shutil.rmtree(download)

print("DONE CLEARING")


#READ IN DATA FILES
x = 0

import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "SECRET.json"

# Initialize the Google Cloud Storage client
storage_client = storage.Client()

# check to see if connected
try:
    buckets = list(storage_client.list_buckets())
    x = 1
except Exception as e:
    print("Authentication failed:", e)




# Base directory to list objects from
base_directory = 'Sigma/Users/'

# Local directory where files will be saved
local_save_directory = 'zip/'
# Ensure the base local directory exists
os.makedirs(local_save_directory, exist_ok=True)


# Define your bucket name and folder path
bucket_name = 'dataswarm-c97d2.appspot.com'
# folder_path1 = 'Sigma/Users/2C8E843F-D2A7-4C2F-AB6E-3559E0B45D6B : iPhone 8/2024-01-22/6/1705904738.8.zip'  # Ensure this ends with a slash
# folder_path2 = '1st offical/Users/AF38881C-08B8-46CB-8973-DBCBB4C4B299 : iPhone 8/2023-11-16/15/1700147165.zip'  # Ensure this ends with a slash

folder_path1 = 'Sigma/Users/'  # Ensure this ends with a slash
folder_path2 = '1st offical/'  # Ensure this ends with a slash


# Get the bucket
bucket = storage_client.get_bucket(bucket_name)


# List all files in the specified folder
blobs1 = bucket.list_blobs(prefix=folder_path1)
blobs2 = bucket.list_blobs(prefix=folder_path2)
zip = 'zip/'
os.makedirs(zip, exist_ok=True)  # This creates the directory if it doesn't exist




for i in blobs1:
    # Parse the user ID and create a subdirectory path
    parts = i.name.split('/')
    # The user ID is expected to be the 3rd component in the blob name, adjust the index as necessary
    user_id = parts[2] if len(parts) > 2 else None

    if user_id:
        # Create a local directory for the user ID, if it doesn't already exist
        user_dir = os.path.join(local_save_directory, user_id)
        os.makedirs(user_dir, exist_ok=True)

        # Define the local file path where the blob will be downloaded
        local_file_path = os.path.join(user_dir, os.path.basename(i.name))

        # Download the blob to the local file path
        i.download_to_filename(local_file_path)

        print(f"Downloaded '{i.name}' to '{local_file_path}'.")

for i in blobs2:
    # Parse the user ID and create a subdirectory path
    parts = i.name.split('/')
    # The user ID is expected to be the 3rd component in the blob name, adjust the index as necessary
    user_id = parts[2] if len(parts) > 2 else None

    if user_id:
        # Create a local directory for the user ID, if it doesn't already exist
        user_dir = os.path.join(local_save_directory, user_id)
        os.makedirs(user_dir, exist_ok=True)

        # Define the local file path where the blob will be downloaded
        local_file_path = os.path.join(user_dir, os.path.basename(i.name))

        # Download the blob to the local file path
        i.download_to_filename(local_file_path)
        print(f"Downloaded '{i.name}' to '{local_file_path}'.")


if x == 1:
  print("FILES READ IN")






#DE-COMPRESS DATAFILES
import gzip
import shutil
import os

# Base directories for compressed and decompressed files
compressed_base = 'zip/'
decompressed_base = 'json/'

# Ensure the decompressed base directory exists
os.makedirs(decompressed_base, exist_ok=True)

# Function to decompress all files in a given directory for a specific user
def decompress_user_files(user_compressed_dir, user_decompressed_dir):
    # Ensure the target directory for the decompressed files exists
    os.makedirs(user_decompressed_dir, exist_ok=True)

    # List all files in the user's compressed directory
    compressed_files = [f for f in os.listdir(user_compressed_dir)]

    # Iterate over each compressed file
    for file_name in compressed_files:
        compressed_file_path = os.path.join(user_compressed_dir, file_name)

        # Construct the path for the decompressed file, replacing '.zip' with '.json'
        decompressed_file_path = os.path.join(user_decompressed_dir, file_name.replace('.zip', '.json'))

        # Decompress the file
        with gzip.open(compressed_file_path, 'rb') as f_in, open(decompressed_file_path, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

        print(f"File decompressed to {decompressed_file_path}")

# Iterate over each subdirectory in the compressed base directory (each representing a user ID)
for user_id_dir in os.listdir(compressed_base):
    user_compressed_dir = os.path.join(compressed_base, user_id_dir)
    if os.path.isdir(user_compressed_dir):
        user_decompressed_dir = os.path.join(decompressed_base, user_id_dir)
        decompress_user_files(user_compressed_dir, user_decompressed_dir)

print("Decompression complete.")

# Optionally, list files in the decompressed directory for verification
for user_id_dir in os.listdir(decompressed_base):
    user_decompressed_dir = os.path.join(decompressed_base, user_id_dir)
    print(f"Files in decompressed directory for {user_id_dir}: {os.listdir(user_decompressed_dir)}")

print("Ready")







#PARSING INTO DATAFRAMES
import pandas as pd
import os
import json


# Mapping of old column names to new column names
column_mapping = {
    "01": "Rotation X",
    "02": "Rotation Y",
    "03": "Rotation Z",
    "04": "Rotation ABS",
    "05": "magnetometer X",
    "06": "magnetometer Y",
    "07": "magnetometer Z",
    "08": "magnetometer ABS",
    "09": "latitude",
    "10": "longitude",
    "11": "altitude",
    "12": "Accelorometer noG X",
    "13": "Accelorometer noG Y",
    "14": "Accelorometer noG Z",
    "15": "Accelorometer noG ABS",
    "16": "Accelorometer WG X",
    "17": "Accelorometer WG Y",
    "18": "Accelorometer WG Z",
    "19": "Accelorometer WG ABS",
    "20": "pitch",
    "21": "yaw",
    "22": "roll",
    "23": "attitude ABS",
    "24": "Pressure",
    "25": "magnetometer Calibrated X",
    "26": "magnetometer Calibrated Y",
    "27": "magnetometer Calibrated Z",
    "28": "magnetometer Calibrated ABS",
    "29": "Charging",
    "30": "batteryLevel"
}


# Directory where decompressed JSON files are stored
decompressed_base = 'json/'

# dictionary for final dataframes for each user // in here will be multiple dataframe for every user
final_dfs = {}



# Iterate over each subdirectory in the decompressed base directory
for user_id_dir in os.listdir(decompressed_base):
    user_decompressed_dir = os.path.join(decompressed_base, user_id_dir)
    if os.path.isdir(user_decompressed_dir):
        # Initialize an empty list to store each DataFrame (file) for this user
        dfs = []

        # List only .json files in this user's decompressed directory
        json_files = [f for f in os.listdir(user_decompressed_dir) if f.endswith('.json')]

        # Iterate over each file in the directory
        for file_name in json_files:
            file_path = os.path.join(user_decompressed_dir, file_name)
            # Check if the file is empty before attempting to read it
            if os.path.getsize(file_path) > 0:
                try:
                  # Read the JSON file
                    with open(file_path, 'r') as file:
                        json_data = json.load(file)

                    # Convert JSON to DataFrame
                    df_list = []
                    for entry in json_data:
                        for key, value in entry.items():
                            temp_df = pd.DataFrame(value, index=[key])
                            temp_df = temp_df.rename(columns=column_mapping)
                            df_list.append(temp_df)

                    df_temp = pd.concat(df_list)


                    # Append the DataFrame to the list
                    dfs.append(df_temp)
                    print(f"Appended {file_name} for user {user_id_dir}")
                except ValueError as e:
                    print(f"Error reading {file_path}: {e}")
            else:
                print(f"Skipping empty file: {file_path}")

        # Concatenate all DataFrames into one DataFrame for this user, if dfs is not empty
        if dfs:
            final_df = pd.concat(dfs, ignore_index=True)

            final_dfs[user_id_dir] = final_df  # Store the final DataFrame for this user in the dictionary
            print(f"DataFrames concatenated for user {user_id_dir}")
        else:
            print(f"No dataframes to concatenate for user {user_id_dir}")

print("ready")


#MAKE ONE TOTAL DATAFRAME
total_df = pd.concat(final_dfs.values(), ignore_index=True)
# print(total_df)
print("Ready")




# CORILATION MATRIX FOR EACH DATAFRAME

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt


#corilation for tatal df
correlation_matrix = total_df.corr()

plt.figure(figsize=(20, 16))
sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
plt.title("Total Correlation Matrix")


save = "download/MatrixNOTIME/"
os.makedirs(save, exist_ok=True)

image_filename = f'download/MatrixNOTIME/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


for i in final_dfs:
  correlation_matrix = final_dfs[i].corr()

  plt.figure(figsize=(20, 16))
  sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
  plt.title(f"Correlation Matrix {i}")

  image_filename = f'download/MatrixNOTIME/cluster_plot_{i}.pdf'  # or '.pdf' for PDF file
  plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
  plt.close()


print("Ready")








save = "download/KMEANSNOTIME/"
os.makedirs(save, exist_ok=True)


#saving for each directory
save1 = "download/KMEANSNOTIME/graph"
os.makedirs(save1, exist_ok=True)

save3 = "download/KMEANSNOTIME/statsfile"
os.makedirs(save3, exist_ok=True)

# Drop rows with any NaN values
clean_df = total_df.dropna().copy()
# Select only numeric columns for clustering
numeric_cols = final_df.select_dtypes(include=[np.number]).columns.tolist()
# Then perform KMeans clustering //setting k num
kmeans = KMeans(n_clusters=4, n_init=10, random_state=0)  # n_init=10 to match current behavior
clean_df['Cluster'] = kmeans.fit_predict(clean_df[numeric_cols])

# If you want to add the cluster labels back to the original DataFrame
total_df['Cluster'] = pd.NA  # Initialize the column with NA
total_df.loc[clean_df.index, 'Cluster'] = clean_df['Cluster']  # Assign cluster labels to the original DataFrame


# Verify the 'Cluster' column is created
if 'Cluster' in total_df.columns:
    print("'Cluster' column created successfully.")
else:
    print("Failed to create 'Cluster' column.")



# Normalize the data
scaler = StandardScaler()
numeric_df = total_df.select_dtypes(include=[np.number])  # Assuming final_df is your data before normalization
numeric_df.replace([np.inf, -np.inf], np.nan, inplace=True)
numeric_df.fillna(numeric_df.mean(), inplace=True)
data_normalized = scaler.fit_transform(numeric_df)

# Continue with the PCA and clustering code
pca = PCA(n_components=0.95)
data_pca = pca.fit_transform(data_normalized)

# Apply clustering on the PCA-reduced data
kkmeans = KMeans(n_clusters=4, n_init=10, random_state=0)  # n_init=10 to match current behavior
clusters = kmeans.fit_predict(data_pca)
total_df['Cluster'] = clusters

# Add the PCA components to the dataframe for visualization
for i in range(data_pca.shape[1]):
    total_df[f'PCA_Component_{i}'] = data_pca[:, i]


for cluster in total_df['Cluster'].unique():
    clusterstats = total_df[total_df['Cluster'] == cluster].describe()

    clusterstats.to_csv('download/KMEANSNOTIME/statsfile/STATSTOTAL.csv')



# Impute the missing values using the mean of each column
imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
imputed_data = imputer.fit_transform(total_df[numeric_cols])

# Now you can perform PCA on the imputed data
pca = PCA(n_components=4)
reduced_data = pca.fit_transform(imputed_data)

# Plotting for the total DataFrame
plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=total_df['Cluster'], cmap='viridis')
plt.xlabel('PCA Component 1')
plt.ylabel('PCA Component 2')
plt.title('PCA - Reduced Data (Total)')
plt.colorbar(label='Cluster')


image_filename = f'download/KMEANSNOTIME/graph/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory



# Perform clustering for each user DataFrame and visualize
for user_id, df in final_dfs.items():
    # Select only numeric columns that exist in this DataFrame
    numeric_cols_in_df = [col for col in numeric_cols if col in df.columns]

    # Impute the missing values using the mean of each column
    imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
    imputed_data = imputer.fit_transform(df[numeric_cols_in_df])

    # Perform KMeans clustering on the imputed data
    kmeans = KMeans(n_clusters=4, n_init=10, random_state=0)  # n_init=10 to match current behavior
    df['Cluster'] = kmeans.fit_predict(imputed_data)

    # Perform PCA on the imputed data
    pca = PCA(n_components=4)
    reduced_data = pca.fit_transform(imputed_data)

    # Plotting for each user's DataFrame
    plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=df['Cluster'], cmap='viridis')
    plt.xlabel('PCA Component 1')
    plt.ylabel('PCA Component 2')
    plt.title(f'PCA - Reduced Data ({user_id})')
    plt.colorbar(label='Cluster')



    image_filename = f'download/KMEANSNOTIME/graph/cluster_plot_{user_id}.pdf'  # or '.pdf' for PDF file
    plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
    plt.close()  # Close the figure to free up memory

    #saving statistics
    for cluster in total_df['Cluster'].unique():
      clusterstats = total_df[total_df['Cluster'] == cluster].describe()

      clusterstats.to_csv(f'download/KMEANSNOTIME/statsfile/STATS{user_id}.csv')



print("Ready")




#PARSING INTO DATAFRAMES with time
import pandas as pd
import os
import json


# Mapping of old column names to new column names
column_mapping = {
    "01": "Rotation X",
    "02": "Rotation Y",
    "03": "Rotation Z",
    "04": "Rotation ABS",
    "05": "magnetometer X",
    "06": "magnetometer Y",
    "07": "magnetometer Z",
    "08": "magnetometer ABS",
    "09": "latitude",
    "10": "longitude",
    "11": "altitude",
    "12": "Accelorometer noG X",
    "13": "Accelorometer noG Y",
    "14": "Accelorometer noG Z",
    "15": "Accelorometer noG ABS",
    "16": "Accelorometer WG X",
    "17": "Accelorometer WG Y",
    "18": "Accelorometer WG Z",
    "19": "Accelorometer WG ABS",
    "20": "pitch",
    "21": "yaw",
    "22": "roll",
    "23": "attitude ABS",
    "24": "Pressure",
    "25": "magnetometer Calibrated X",
    "26": "magnetometer Calibrated Y",
    "27": "magnetometer Calibrated Z",
    "28": "magnetometer Calibrated ABS",
    "29": "Charging",
    "30": "batteryLevel"
}


# Directory where decompressed JSON files are stored
decompressed_base = 'json/'

# dictionary for final dataframes for each user // in here will be multiple dataframe for every user
final_dfs_time = {}

# Iterate over each subdirectory in the decompressed base directory
for user_id_dir in os.listdir(decompressed_base):
    user_decompressed_dir = os.path.join(decompressed_base, user_id_dir)
    if os.path.isdir(user_decompressed_dir):
        # Initialize an empty list to store each DataFrame (file) for this user
        dfs_time = []

        # List only .json files in this user's decompressed directory
        json_files = [f for f in os.listdir(user_decompressed_dir) if f.endswith('.json')]

        # Iterate over each file in the directory
        for file_name in json_files:
            file_path = os.path.join(user_decompressed_dir, file_name)
            # Check if the file is empty before attempting to read it
            if os.path.getsize(file_path) > 0:
                try:
                  # Read the JSON file
                    with open(file_path, 'r') as file:
                        json_list = json.load(file)  # json_list because we expect a list here



                        df_list_time = []
                        for json_entry in json_list:  # Iterate through the list
                            for epoch_time, values in json_entry.items():  # json_entry is the dictionary we expected
                                temp_df_time = pd.DataFrame([values], index=[0]).rename(columns=column_mapping)
                                temp_df_time['time'] = epoch_time

                                # Reorder the DataFrame to put 'time' first
                                cols = ['time'] + [col for col in temp_df_time.columns if col != 'time']
                                temp_df_time = temp_df_time[cols]

                                df_list_time.append(temp_df_time)

                    if df_list_time:  # Check if there are any data frames to concatenate
                        df_temp_time = pd.concat(df_list_time).reset_index(drop=True)
                        dfs_time.append(df_temp_time)
                        print(f"Appended {file_name} for user {user_id_dir}")
                    else:
                        print(f"No valid data in {file_name} for user {user_id_dir}")




                    # Concatenate all temporary DataFrames into one
                    df_temp_time = pd.concat(df_list_time).reset_index(drop=True)

                    # Append the DataFrame to the list
                    dfs_time.append(df_temp_time)
                    print(f"Appended {file_name} for user {user_id_dir}")
                except ValueError as e:
                    print(f"Error reading {file_path}: {e}")
            else:
                print(f"Skipping empty file: {file_path}")

        # Concatenate all DataFrames into one DataFrame for this user, if dfs is not empty
        if dfs_time:
            final_df_time = pd.concat(dfs_time, ignore_index=True)
            final_dfs_time[user_id_dir] = final_df_time  # Store the final DataFrame for this user in the dictionary
            print(f"DataFrames concatenated for user {user_id_dir}")
        else:
            print(f"No dataframes to concatenate for user {user_id_dir}")

print("ready")




#MAKE ONE TOTAL DATAFRAME
total_df_time = pd.concat(final_dfs_time.values(), ignore_index=True)
# print(total_df)
print("Ready")








#saving for each directory
save = "download/KMEANS_WithTime/"
os.makedirs(save, exist_ok=True)

save = "download/KMEANS_WithTime/EPOCH/"
os.makedirs(save, exist_ok=True)

save1 = "download/KMEANS_WithTime/EPOCH/graph"
os.makedirs(save1, exist_ok=True)

save3 = "download/KMEANS_WithTime/EPOCH/statsfile"
os.makedirs(save3, exist_ok=True)

# Drop rows with any NaN values
clean_df_time = total_df_time.dropna().copy()
# Select only numeric columns for clustering
numeric_cols = final_df_time.select_dtypes(include=[np.number]).columns.tolist()
# Then perform KMeans clustering
kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
clean_df_time['Cluster'] = kmeans.fit_predict(clean_df_time[numeric_cols])

# If you want to add the cluster labels back to the original DataFrame
total_df_time['Cluster'] = pd.NA  # Initialize the column with NA
total_df_time.loc[clean_df_time.index, 'Cluster'] = clean_df_time['Cluster']  # Assign cluster labels to the original DataFrame


# Verify the 'Cluster' column is created
if 'Cluster' in total_df_time.columns:
    print("'Cluster' column created successfully for total.")
else:
    print("Failed to create 'Cluster' column for total.")



# Normalize the data
scaler = StandardScaler()
numeric_df_time = total_df_time.select_dtypes(include=[np.number])
numeric_df_time.replace([np.inf, -np.inf], np.nan, inplace=True)
numeric_df_time.fillna(numeric_df_time.mean(), inplace=True)
data_normalized = scaler.fit_transform(numeric_df_time)

# Continue with the PCA and clustering code
pca = PCA(n_components=0.95)
data_pca = pca.fit_transform(data_normalized)

# Apply clustering on the PCA-reduced data
kkmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
clusters = kmeans.fit_predict(data_pca)
total_df_time['Cluster'] = clusters

# Add the PCA components to the dataframe for visualization
for i in range(data_pca.shape[1]):
    total_df_time[f'PCA_Component_{i}'] = data_pca[:, i]


for cluster in total_df_time['Cluster'].unique():
    clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()

    clusterstats.to_csv('download/KMEANS_WithTime/EPOCH/statsfile/STATSTOTAL.csv')



# Impute the missing values using the mean of each column
imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
imputed_data = imputer.fit_transform(total_df_time[numeric_cols])

# Now you can perform PCA on the imputed data
pca = PCA(n_components=2)
reduced_data = pca.fit_transform(imputed_data)

# Plotting for the total DataFrame
plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=total_df_time['Cluster'], cmap='viridis')
plt.xlabel('PCA Component 1')
plt.ylabel('PCA Component 2')
plt.title('PCA - Reduced Data (Total)')
plt.colorbar(label='Cluster')


image_filename = f'download/KMEANS_WithTime/EPOCH/graph/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory






# Perform clustering for each user DataFrame and visualize
# Perform clustering for each user DataFrame and visualize
for user_id, df_time in final_dfs_time.items():
    # Select only numeric columns that exist in this DataFrame
    numeric_cols_in_df_time = [col for col in numeric_cols if col in df_time.columns]

    # Impute the missing values using the mean of each column
    imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
    imputed_data = imputer.fit_transform(df_time[numeric_cols_in_df_time])

    # Perform KMeans clustering on the imputed data
    kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
    df_time['Cluster'] = kmeans.fit_predict(imputed_data)

    # Perform PCA on the imputed data
    pca = PCA(n_components=2)
    reduced_data = pca.fit_transform(imputed_data)

     # Add the PCA components to the dataframe for visualization
    for i in range(reduced_data.shape[1]):  # Use reduced_data instead of data_pca
        df_time[f'PCA_Component_{i}'] = reduced_data[:, i]  # Use reduced_data instead of data_pca

    # Plotting for each user's DataFrame
    plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=df_time['Cluster'], cmap='viridis')
    plt.xlabel('PCA Component 1')
    plt.ylabel('PCA Component 2')
    plt.title(f'PCA - Reduced Data ({user_id})')
    plt.colorbar(label='Cluster')

    image_filename = f'download/KMEANS_WithTime/EPOCH/graph/cluster_plot_{user_id}.pdf'  # or '.pdf' for PDF file
    plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
    plt.close()  # Close the figure to free up memory

    # Saving statistics
    for cluster in df_time['Cluster'].unique():
        clusterstats = df_time[df_time['Cluster'] == cluster].describe()
        clusterstats.to_csv(f'download/KMEANS_WithTime/EPOCH/statsfile/STATS{user_id}.csv')


columns_to_remove = ["PCA_Component_0", "PCA_Component_1",
                     "PCA_Component_2", "PCA_Component_3", "PCA_Component_4",
                     "PCA_Component_5", "PCA_Component_6", "PCA_Component_7"]

total_df_time.drop(columns=columns_to_remove, inplace=True)

# total_df_time.head(10).to_csv('download/KMEANS_WithTime/EPOCH/totalcsvfile/NO_time_clustered_dataTOTAL.csv', index=False)

print("Ready")






# CORILATION MATRIX FOR EPOCH

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt

#corilation for tatal df
correlation_matrix = total_df_time.corr()

plt.figure(figsize=(20, 16))
sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
plt.title("Total Correlation Matrix EPOCH")


save = "download/MatrixWITHtime/"
os.makedirs(save, exist_ok=True)

save = "download/MatrixWITHtime/EPOCH/"
os.makedirs(save, exist_ok=True)

save = "download/MatrixWITHtime/EPOCH/"
os.makedirs(save, exist_ok=True)

image_filename = f'download/MatrixWITHtime/EPOCH/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


for i in final_dfs_time:
  correlation_matrix = final_dfs_time[i].corr()

  plt.figure(figsize=(20, 16))
  sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
  plt.title(f"Correlation Matrix {i}")

  image_filename = f'download/MatrixWITHtime/EPOCH/cluster_plot_{i}.pdf'  # or '.pdf' for PDF file
  plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
  plt.close()

print("Ready")





# Doing time for miniute of day // converting epoch to minuite

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Assuming 'time' is your epoch time column in milliseconds
total_df_time['datetime'] = pd.to_datetime(total_df_time['time'], unit='s')

# Extract minute of the day
total_df_time['minute_of_day'] = total_df_time['datetime'].dt.hour * 60 + total_df_time['datetime'].dt.minute

# Convert to cyclical features
total_df_time['sin_minute'] = np.sin(2 * np.pi * total_df_time['minute_of_day'] / (24 * 60))
total_df_time['cos_minute'] = np.cos(2 * np.pi * total_df_time['minute_of_day'] / (24 * 60))

# Drop the original 'time' column
total_df_time.drop(columns=['time'], inplace=True)







#saving for each directory
save = "download/KMEANS_WithTime/Minute/"
os.makedirs(save, exist_ok=True)

save1 = "download/KMEANS_WithTime/Minute/graph"
os.makedirs(save1, exist_ok=True)

save3 = "download/KMEANS_WithTime/Minute/statsfile"
os.makedirs(save3, exist_ok=True)

# Create a new DataFrame by dropping the 'datetime' column
new_df = total_df_time.drop(columns=['datetime']).copy()

# Drop rows with any NaN values
clean_df_time = new_df.dropna().copy()

# Select only numeric columns for clustering
numeric_cols = clean_df_time.select_dtypes(include=[np.number]).columns.tolist()

# Then perform KMeans clustering
kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior

try:
    clean_df_time['Cluster'] = kmeans.fit_predict(clean_df_time[numeric_cols])
except:
    pass

# If you want to add the cluster labels back to the original DataFrame
total_df_time['Cluster'] = pd.NA  # Initialize the column with NA
total_df_time.loc[clean_df_time.index, 'Cluster'] = clean_df_time['Cluster']  # Assign cluster labels to the original DataFrame

# Verify the 'Cluster' column is created
if 'Cluster' in total_df_time.columns:
    print("'Cluster' column created successfully.")
else:
    print("Failed to create 'Cluster' column.")

# Normalize the data
scaler = StandardScaler()
numeric_df_time = total_df_time.select_dtypes(include=[np.number])
numeric_df_time.replace([np.inf, -np.inf], np.nan, inplace=True)
numeric_df_time.fillna(numeric_df_time.mean(), inplace=True)
data_normalized = scaler.fit_transform(numeric_df_time)

# Continue with the PCA and clustering code
pca = PCA(n_components=0.95)
data_pca = pca.fit_transform(data_normalized)

# Apply clustering on the PCA-reduced data
kkmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
clusters = kmeans.fit_predict(data_pca)
total_df_time['Cluster'] = clusters

# Add the PCA components to the DataFrame for visualization
for i in range(data_pca.shape[1]):
    total_df_time[f'PCA_Component_{i}'] = data_pca[:, i]

for cluster in total_df_time['Cluster'].unique():
    clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()
    clusterstats.to_csv('download/KMEANS_WithTime/Minute/statsfile/STATSTOTAL.csv')

# Impute the missing values using the mean of each column
imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
imputed_data = imputer.fit_transform(numeric_df_time)

# Now you can perform PCA on the imputed data
pca = PCA(n_components=2)
reduced_data = pca.fit_transform(imputed_data)

# Plotting for the total DataFrame
plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=total_df_time['Cluster'], cmap='viridis')
plt.xlabel('PCA Component 1')
plt.ylabel('PCA Component 2')
plt.title('PCA - Reduced Data (Total)')
plt.colorbar(label='Cluster')

image_filename = f'download/KMEANS_WithTime/Minute/graph/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory





# Perform clustering for each user DataFrame and visualize
for user_id, df_time in final_dfs_time.items():
    # Select only numeric columns that exist in this DataFrame
    numeric_cols_in_df_time = [col for col in numeric_cols if col in df_time.columns]

    # Impute the missing values using the mean of each column
    imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
    imputed_data = imputer.fit_transform(df_time[numeric_cols_in_df_time])

    # Perform KMeans clustering on the imputed data
    kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
    df_time['Cluster'] = kmeans.fit_predict(imputed_data)

    # Perform PCA on the imputed data
    pca = PCA(n_components=2)
    reduced_data = pca.fit_transform(imputed_data)

    # Plotting for each user's DataFrame
    plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=df_time['Cluster'], cmap='viridis')
    plt.xlabel('PCA Component 1')
    plt.ylabel('PCA Component 2')
    plt.title(f'PCA - Reduced Data ({user_id})')
    plt.colorbar(label='Cluster')



    image_filename = f'download/KMEANS_WithTime/Minute/graph/cluster_plot_{user_id}.pdf' # or '.pdf' for PDF file
    plt.savefig(image_filename, bbox_inches='tight')
    # bbox_inches='tight' is optional but often useful
    plt.close()  # Close the figure to free up memory

    #saving statistics
    for cluster in total_df_time['Cluster'].unique():
      clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()

      clusterstats.to_csv(f'download/KMEANS_WithTime/Minute/statsfile/STATS{user_id}.csv')


columns_to_remove = ["PCA_Component_0", "PCA_Component_1",
                     "PCA_Component_2", "PCA_Component_3", "PCA_Component_4",
                     "PCA_Component_5", "PCA_Component_6", "PCA_Component_7"]

total_df_time.drop(columns=columns_to_remove, inplace=True)

print("Ready")





# CORILATION MATRIX FOR EPOCH

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt


#corilation for tatal df
correlation_matrix = total_df_time.corr()

plt.figure(figsize=(20, 16))
sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
plt.title("Total Correlation Matrix Minute")


save = "download/MatrixWITHtime/Minute/"
os.makedirs(save, exist_ok=True)


image_filename = f'download/MatrixWITHtime/Minute/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


for i in final_dfs_time:
  correlation_matrix = final_dfs_time[i].corr()

  plt.figure(figsize=(20, 16))
  sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
  plt.title(f"Correlation Matrix {i}")

  image_filename = f'download/MatrixWITHtime/Minute/cluster_plot_{i}.pdf'  # or '.pdf' for PDF file
  plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
  plt.close()

print("Ready")





#DOING THE SAME FOR HOUR

# Extract hour of the day
total_df_time['hour_of_day'] = total_df_time['datetime'].dt.hour

# Convert to cyclical features
total_df_time['sin_hour'] = np.sin(2 * np.pi * total_df_time['hour_of_day'] / 24)
total_df_time['cos_hour'] = np.cos(2 * np.pi * total_df_time['hour_of_day'] / 24)

columns_to_remove = ["minute_of_day", "sin_minute",
                     "cos_minute"]
try:
  total_df_time.drop(columns=columns_to_remove, inplace=True)
except:
  pass







#saving for each directory

save = "download/KMEANS_WithTime/HOUR/"
os.makedirs(save, exist_ok=True)

save1 = "download/KMEANS_WithTime/HOUR/graph"
os.makedirs(save1, exist_ok=True)

save3 = "download/KMEANS_WithTime/HOUR/statsfile"
os.makedirs(save3, exist_ok=True)

# Create a new DataFrame by dropping the 'datetime' column
new_df = total_df_time.drop(columns=['datetime']).copy()

# Drop rows with any NaN values
clean_df_time = new_df.dropna().copy()

# Select only numeric columns for clustering
numeric_cols = clean_df_time.select_dtypes(include=[np.number]).columns.tolist()

# Then perform KMeans clustering
kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior

try:
    clean_df_time['Cluster'] = kmeans.fit_predict(clean_df_time[numeric_cols])
except:
    pass

# If you want to add the cluster labels back to the original DataFrame
total_df_time['Cluster'] = pd.NA  # Initialize the column with NA
total_df_time.loc[clean_df_time.index, 'Cluster'] = clean_df_time['Cluster']  # Assign cluster labels to the original DataFrame

# Verify the 'Cluster' column is created
if 'Cluster' in total_df_time.columns:
    print("'Cluster' column created successfully.")
else:
    print("Failed to create 'Cluster' column.")

# Normalize the data
scaler = StandardScaler()
numeric_df_time = total_df_time.select_dtypes(include=[np.number])
numeric_df_time.replace([np.inf, -np.inf], np.nan, inplace=True)
numeric_df_time.fillna(numeric_df_time.mean(), inplace=True)
data_normalized = scaler.fit_transform(numeric_df_time)

# Continue with the PCA and clustering code
pca = PCA(n_components=0.95)
data_pca = pca.fit_transform(data_normalized)

# Apply clustering on the PCA-reduced data
kkmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
clusters = kmeans.fit_predict(data_pca)
total_df_time['Cluster'] = clusters

# Add the PCA components to the DataFrame for visualization
for i in range(data_pca.shape[1]):
    total_df_time[f'PCA_Component_{i}'] = data_pca[:, i]

for cluster in total_df_time['Cluster'].unique():
    clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()
    clusterstats.to_csv('download/KMEANS_WithTime/HOUR/statsfile/STATSTOTAL.csv')

# Impute the missing values using the mean of each column
imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
imputed_data = imputer.fit_transform(numeric_df_time)

# Now you can perform PCA on the imputed data
pca = PCA(n_components=2)
reduced_data = pca.fit_transform(imputed_data)

# Plotting for the total DataFrame
plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=total_df_time['Cluster'], cmap='viridis')
plt.xlabel('PCA Component 1')
plt.ylabel('PCA Component 2')
plt.title('PCA - Reduced Data (Total)')
plt.colorbar(label='Cluster')

image_filename = f'download/KMEANS_WithTime/HOUR/graph/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory



# Perform clustering for each user DataFrame and visualize
for user_id, df_time in final_dfs_time.items():
    # Select only numeric columns that exist in this DataFrame
    numeric_cols_in_df_time = [col for col in numeric_cols if col in df_time.columns]

    # Impute the missing values using the mean of each column
    imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
    imputed_data = imputer.fit_transform(df_time[numeric_cols_in_df_time])

    # Perform KMeans clustering on the imputed data
    kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
    df_time['Cluster'] = kmeans.fit_predict(imputed_data)

    # Perform PCA on the imputed data
    pca = PCA(n_components=2)
    reduced_data = pca.fit_transform(imputed_data)

    # Plotting for each user's DataFrame
    plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=df_time['Cluster'], cmap='viridis')
    plt.xlabel('PCA Component 1')
    plt.ylabel('PCA Component 2')
    plt.title(f'PCA - Reduced Data ({user_id})')
    plt.colorbar(label='Cluster')



    image_filename = f'download/KMEANS_WithTime/HOUR/graph/cluster_plot_{user_id}.pdf' # or '.pdf' for PDF file
    plt.savefig(image_filename, bbox_inches='tight')
    # bbox_inches='tight' is optional but often useful
    plt.close()  # Close the figure to free up memory

    #saving statistics
    for cluster in total_df_time['Cluster'].unique():
      clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()

      clusterstats.to_csv(f'download/KMEANS_WithTime/HOUR/statsfile/STATS{user_id}.csv')


columns_to_remove = ["PCA_Component_0", "PCA_Component_1",
                     "PCA_Component_2", "PCA_Component_3", "PCA_Component_4",
                     "PCA_Component_5", "PCA_Component_6", "PCA_Component_7"]

total_df_time.drop(columns=columns_to_remove, inplace=True)

print("Ready")







# CORILATION MATRIX FOR EPOCH

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt


#corilation for tatal df
correlation_matrix = total_df_time.corr()

plt.figure(figsize=(20, 16))
sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
plt.title("Total Correlation Matrix HOUR")


save = "download/MatrixWITHtime/HOUR/"
os.makedirs(save, exist_ok=True)


image_filename = f'download/MatrixWITHtime/HOUR/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


for i in final_dfs_time:
  correlation_matrix = final_dfs_time[i].corr()

  plt.figure(figsize=(20, 16))
  sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
  plt.title(f"Correlation Matrix {i}")

  image_filename = f'download/MatrixWITHtime/HOUR/cluster_plot_{i}.pdf'  # or '.pdf' for PDF file
  plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
  plt.close()

print("Ready")







#DOING IT FOR DAY OF WEEK

# Extract day of the week (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
total_df_time['day_of_week'] = total_df_time['datetime'].dt.dayofweek

# Convert to cyclical features
total_df_time['sin_day'] = np.sin(2 * np.pi * total_df_time['day_of_week'] / 7)
total_df_time['cos_day'] = np.cos(2 * np.pi * total_df_time['day_of_week'] / 7)

# Remove any existing columns related to the minute or hour of the day
columns_to_remove = ["hour_of_day", "minute_of_day", "sin_hour", "cos_hour", "sin_minute", "cos_minute"]
total_df_time.drop(columns=columns_to_remove, inplace=True, errors='ignore')









#saving for each directory

save = "download/KMEANS_WithTime/DAY/"
os.makedirs(save, exist_ok=True)

save1 = "download/KMEANS_WithTime/DAY/graph"
os.makedirs(save1, exist_ok=True)

save3 = "download/KMEANS_WithTime/DAY/statsfile"
os.makedirs(save3, exist_ok=True)

# Create a new DataFrame by dropping the 'datetime' column
new_df = total_df_time.drop(columns=['datetime']).copy()

# Drop rows with any NaN values
clean_df_time = new_df.dropna().copy()

# Select only numeric columns for clustering
numeric_cols = clean_df_time.select_dtypes(include=[np.number]).columns.tolist()

# Then perform KMeans clustering
kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior

try:
    clean_df_time['Cluster'] = kmeans.fit_predict(clean_df_time[numeric_cols])
except:
    pass

# If you want to add the cluster labels back to the original DataFrame
total_df_time['Cluster'] = pd.NA  # Initialize the column with NA
total_df_time.loc[clean_df_time.index, 'Cluster'] = clean_df_time['Cluster']  # Assign cluster labels to the original DataFrame

# Verify the 'Cluster' column is created
if 'Cluster' in total_df_time.columns:
    print("'Cluster' column created successfully.")
else:
    print("Failed to create 'Cluster' column.")

# Normalize the data
scaler = StandardScaler()
numeric_df_time = total_df_time.select_dtypes(include=[np.number])
numeric_df_time.replace([np.inf, -np.inf], np.nan, inplace=True)
numeric_df_time.fillna(numeric_df_time.mean(), inplace=True)
data_normalized = scaler.fit_transform(numeric_df_time)

# Continue with the PCA and clustering code
pca = PCA(n_components=0.95)
data_pca = pca.fit_transform(data_normalized)

# Apply clustering on the PCA-reduced data
kkmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
clusters = kmeans.fit_predict(data_pca)
total_df_time['Cluster'] = clusters

# Add the PCA components to the DataFrame for visualization
for i in range(data_pca.shape[1]):
    total_df_time[f'PCA_Component_{i}'] = data_pca[:, i]

for cluster in total_df_time['Cluster'].unique():
    clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()
    clusterstats.to_csv('download/KMEANS_WithTime/DAY/statsfile/STATSTOTAL.csv')

# Impute the missing values using the mean of each column
imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
imputed_data = imputer.fit_transform(numeric_df_time)

# Now you can perform PCA on the imputed data
pca = PCA(n_components=2)
reduced_data = pca.fit_transform(imputed_data)

# Plotting for the total DataFrame
plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=total_df_time['Cluster'], cmap='viridis')
plt.xlabel('PCA Component 1')
plt.ylabel('PCA Component 2')
plt.title('PCA - Reduced Data (Total)')
plt.colorbar(label='Cluster')

image_filename = f'download/KMEANS_WithTime/DAY/graph/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


# Perform clustering for each user DataFrame and visualize
for user_id, df_time in final_dfs_time.items():
    # Select only numeric columns that exist in this DataFrame
    numeric_cols_in_df_time = [col for col in numeric_cols if col in df_time.columns]

    # Impute the missing values using the mean of each column
    imputer = SimpleImputer(missing_values=np.nan, strategy='mean')
    imputed_data = imputer.fit_transform(df_time[numeric_cols_in_df_time])

    # Perform KMeans clustering on the imputed data
    kmeans = KMeans(n_clusters=3, n_init=10, random_state=0)  # n_init=10 to match current behavior
    df_time['Cluster'] = kmeans.fit_predict(imputed_data)

    # Perform PCA on the imputed data
    pca = PCA(n_components=2)
    reduced_data = pca.fit_transform(imputed_data)

    # Plotting for each user's DataFrame
    plt.scatter(reduced_data[:, 0], reduced_data[:, 1], c=df_time['Cluster'], cmap='viridis')
    plt.xlabel('PCA Component 1')
    plt.ylabel('PCA Component 2')
    plt.title(f'PCA - Reduced Data ({user_id})')
    plt.colorbar(label='Cluster')

    image_filename = f'download/KMEANS_WithTime/DAY/graph/cluster_plot_{user_id}.pdf' # or '.pdf' for PDF file
    plt.savefig(image_filename, bbox_inches='tight')
    # bbox_inches='tight' is optional but often useful
    plt.close()  # Close the figure to free up memory

    #saving statistics
    for cluster in total_df_time['Cluster'].unique():
      clusterstats = total_df_time[total_df_time['Cluster'] == cluster].describe()

      clusterstats.to_csv(f'download/KMEANS_WithTime/DAY/statsfile/STATS{user_id}.csv')

columns_to_remove = ["PCA_Component_0", "PCA_Component_1",
                     "PCA_Component_2", "PCA_Component_3", "PCA_Component_4",
                     "PCA_Component_5", "PCA_Component_6", "PCA_Component_7"]

total_df_time.drop(columns=columns_to_remove, inplace=True)

print("Ready")







# CORILATION MATRIX

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib.pyplot as plt


#corilation for tatal df
correlation_matrix = total_df_time.corr()

plt.figure(figsize=(20, 16))
sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
plt.title("Total Correlation Matrix DAY")


save = "download/MatrixWITHtime/DAY/"
os.makedirs(save, exist_ok=True)


image_filename = f'download/MatrixWITHtime/DAY/cluster_plot_TOTAL.pdf'  # or '.pdf' for PDF file
plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
plt.close()  # Close the figure to free up memory


for i in final_dfs_time:
  correlation_matrix = final_dfs_time[i].corr()

  plt.figure(figsize=(20, 16))
  sns.heatmap(correlation_matrix, annot=True, fmt=".2f", cmap='coolwarm')
  plt.title(f"Correlation Matrix {i}")

  image_filename = f'download/MatrixWITHtime/DAY/cluster_plot_{i}.pdf'  # or '.pdf' for PDF file
  plt.savefig(image_filename, bbox_inches='tight')  # bbox_inches='tight' is optional but often useful
  plt.close()

print("Ready")

save = "download/MAP/"
os.makedirs(save, exist_ok=True)

# Create a Folium map centered around the mean latitude and longitude
map_center = [total_df_time['latitude'].mean(), total_df_time['longitude'].mean()]
mymap = folium.Map(location=map_center, zoom_start=10)

# Convert latitude and longitude points to a list of lists
points = total_df_time[['latitude', 'longitude']].values.tolist()

# Add a heatmap layer to the map
HeatMap(points).add_to(mymap)

# Save the map to an HTML file
mymap.save('download/MAP/heatmap.html')





print("COMPLETED")
