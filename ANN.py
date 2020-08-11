import keras
import numpy as np
import mnist
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.utils import to_categorical

train_images = mnist.train_images()
train_labels = mnist.train_labels()
test_images = mnist.test_images()
test_labels = mnist.test_labels()

# Normalize the images.
train_images = (train_images / 255) - 0.5
test_images = (test_images / 255) - 0.5
print(train_images.shape)
#print(test_images.shape)
train_images = train_images.transpose(1,2,0)
train_images = tf.image.resize(train_images, (16,16)).numpy()
train_images = train_images.transpose(2,0,1)
print("new size train images: ", train_images.shape)
test_images = test_images.transpose(1,2,0)
test_images = tf.image.resize(test_images, (16,16)).numpy()
test_images = test_images.transpose(2,0,1)
print("new size test images: ", test_images.shape)
# Flatten the images.
train_images = train_images.reshape((-1, 256))
test_images = test_images.reshape((-1, 256))
print(train_images.shape)
# Build the model.
model = Sequential([
  Dense(10, activation='softmax', input_shape=(256,)),
  
])
# Compile the model.
model.compile(
  optimizer='adam',
  loss='categorical_crossentropy',
  metrics=['accuracy'],
)

# Train the model.
model.fit(
  train_images,
  to_categorical(train_labels),
  epochs=5,
  batch_size=32,
)

# Evaluate the model.
model.evaluate(
  test_images,
  to_categorical(test_labels)
)

# Save the model to disk.
model.save_weights('model.h5')

# # Load the model from disk later using:
# # model.load_weights('model.h5')

# # Predict on the first 5 test images.
# predictions = model.predict(test_images[:5])

# # Print our model's predictions.
# print(np.argmax(predictions, axis=1)) # [7, 2, 1, 0, 4]

# # Check our predictions against the ground truths.
# print(test_labels[:5]) # [7, 2, 1, 0, 4]