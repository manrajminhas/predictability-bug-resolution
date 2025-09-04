# Use of LLMs in This Project

This project used Large Language Models (LLMs) as pair-programming assistants and for conceptual understanding. The following is a summary of its advantages and disadvantages in this context.

### Advantages

- **Conceptual Understanding and Guidance:** The LLM was very important in navigating the data science lifecycle. It helped classify the machine learning problem (supervised regression), explained the rationale behind key methodological choices (e.g., using the median baseline for skewed data, log-transforming the target variable), and provided a structured overview of suitable modeling techniques, allowing for a more methodical approach.
- **R Scripting and Implementation:** The LLM was highly effective at generating and incrementally updating the R scripts for the entire analysis. It successfully wrote code for data loading, preprocessing, creating complex visualizations with `ggplot2`, and implementing the experimental loops for all three research questions.

### Disadvantages

- **Debugging Complex Errors:** The LLM's primary weakness was in debugging. When the R script would hang or fail without a clear error message (e.g., during the `caret` tuning process), its suggestions were often generic and not effective at diagnosing the root cause, which required a more human-driven approach to solve.
- **Lack of Deep, Contextual Interpretation:** While the LLM could interpret numerical results (e.g., "the MAE is high"), it could not provide a deep, domain-specific reason for *why* the model ultimately underperformed. It lacks the real-world context to reason about uncaptured factors like developer workload or the inherent difficulty of predicting a complex human process.

### A Note on Scope

This document presents two prompt-and-response sequences to illustrate the LLM use. Across various chat sessions and models, dozens of such sequences were generated. For the sake of clarity and to keep this document manageable, we have selected these two representative examples. Displaying the complete history would result in an overly large and cumbersome file.

The two sequences of prompts included below showcase the back-and-forth interaction between our team and the LLMs used in this project (various models from Gemini and ChatGPT). The first sequence maps to the "Conceptual Understanding and Guidance" use case, where we defined the problem and modeling strategy. The second sequence maps to the "R Scripting and Implementation" use case, where we developed the code for our exploratory data analysis. The actual canvas containing the code was omitted.

---

## Sequence 1: ML Problem Definition and Model Strategy

This sequence guided in determining the machine learning problem and selecting the most appropriate modeling approach.

---

### Prompt 1.1

this is what i have so far. i would like you to classify the type of problem this is in terms of machine learning, give a detailed list of the most popular models for this problem type, explaining which ones are most suited for this dataset i have.

### Response 1.1

Of course. Based on your project goals and the data you've explored, we can now define the machine learning problem and identify the most suitable models.

This is a **Supervised Regression** problem.

- **Supervised Learning** because you have a dataset with historical outcomes (the `resolution_time`) that you want the model to learn from.
- **Regression task** because the target variable you are trying to predict, `log_resolution_time`, is a continuous numerical value, not a distinct category

The goal is to predict *how much time*, not *what kind* of bug it is.

#### Popular Models for Regression Problems

Here is a list of common and powerful models used for this type of regression task, from simple to more complex.

- **Baseline Model**: This isn't a true model but a simple heuristic to measure against. For example, always predicting the average resolution time. Any useful model must perform better than this.
- **Linear Regression**: The classic starting point. It finds the best straight-line relationship between the predictor features and the target variable.
- **Regularized Linear Models (Ridge, Lasso)**: These are improved versions of linear regression that add penalties to prevent overfitting and can perform a type of automatic feature selection (Lasso).
- **k-Nearest Neighbors (k-NN) Regression**: A simple, non-linear model that makes predictions based on the average outcome of the 'k' most similar data points in the training set.
- **Decision Tree Regression**: A model that splits the data into branches based on feature values to make a prediction. It's easy to interpret but can overfit easily.
- **Random Forest Regression**: An ensemble model that builds hundreds of individual decision trees and averages their predictions. This makes it much more powerful and robust than a single tree.
- **Gradient Boosting Machines (GBM, XGBoost, LightGBM)**: The most powerful class of models for tabular data like yours. These are also ensemble models that build trees sequentially, with each new tree learning to correct the errors of the previous ones.

#### Which Models Are Most Suited for Your Dataset?

Based on the insights from your excellent EDA, some models are much better suited than others.

**Top Recommendations: Tree-Based Ensembles**

Your best-performing and most suitable models will almost certainly be **Random Forest** and **Gradient Boosting** (specifically XGBoost or LightGBM).

*Why they are a perfect fit:*

- **They Excel at Non-Linear Relationships**: Your EDA clearly showed that many features (like `num_comments` or `watch_count`) have complex, non-linear relationships with resolution time. Tree-based models can capture these patterns automatically.
- **They Are Robust to Multicollinearity**: The moderate correlation you found between `watch_count` and `num_comments` is not an issue for these models.
- **They Handle Feature Interactions**: These models can naturally learn if the effect of one feature changes based on the value of another.
- **They Provide Feature Importance**: A key output is a ranking of which features were most useful for making predictions, which will be essential for your analysis.

**Important Baseline Model: Linear Regression**

You should still build a Linear Regression model, not because you expect it to perform well, but because it serves as a crucial baseline.

*Why it's important:*

- **It Will Likely Perform Poorly**: Because it cannot handle the non-linear relationships in your data, it will probably not be very accurate.
- **It Proves the Need for Better Models**: By showing that a simple linear model is insufficient, you provide a strong justification for using more complex models like Random Forest.

#### Summary and Action Plan

- **Start with a Baseline**: Build a simple Linear Regression model. This will be your benchmark for performance.
- **Build Your Main Models**: Develop a Random Forest model and a Gradient Boosting model. These are expected to perform the best.
- **Compare Performance**: Evaluate all three models using regression metrics (like Mean Absolute Error or R-squared) to quantify their performance.

---

### Prompt 1.2

for the baseline model wouldn't it be better to select the mean? why aren't k-Nearest Neighbors and Decision Tree Regression apropriate here, aren't they non linear? and should i choose Random Forest Regression or Gradient Boosting Machines? what is the difference between the two?

### Response 1.2

#### Baseline Model: Mean vs. Median

For skewed data like your original `resolution_time`, the **median** is a better choice for a baseline model. The mean is highly sensitive to outliers. In your data, a few bugs that took thousands of days to resolve pull the mean up significantly, making it unrepresentative of a typical bug. The median is much more robust to these extreme values.

#### Suitability of k-NN and Decision Trees

You're right, both are non-linear models. However, they are generally less suitable than the more advanced ensemble methods for a few key reasons:

- **Single Decision Trees** are prone to high variance and can overfit the training data, learning its noise and specific quirks rather than the underlying patterns.
- **k-Nearest Neighbors (k-NN)** can be computationally expensive on large datasets and is very sensitive to the scaling of the features. Its performance tends to degrade as the number of predictors increases (a problem known as the "curse of dimensionality").

Ensemble models like Random Forest were specifically invented to overcome the instability of single decision trees.

#### Random Forest vs. Gradient Boosting

You don't necessarily have to choose one; it's common practice to try both. The main difference lies in *how* they build their collection of trees.

- **Random Forest (Bagging)**: Builds hundreds of decision trees in **parallel**. Each tree is trained on a random subset of the data and features. The final prediction is the average of all the individual trees' predictions. It's like asking a large, diverse group of experts for their opinion and averaging their answers.
- **Gradient Boosting (Boosting)**: Builds trees **sequentially**. The first tree makes a prediction. The second tree is then trained to predict the errors made by the first tree, and so on. The final prediction is the sum of the predictions from all the trees. It's like assembling a team of specialists where each new member is hired specifically to fix the mistakes of the previous one.

**Recommendation**: Start with Random Forest as it's generally easier to tune. Then, build a Gradient Boosting model to see if you can get a performance increase.

---

### Prompt 1.3

for non-linear regression modelling, what is the strongest model and most accurate model?

### Response 1.3

For non-linear regression on structured, tabular data like yours, the strongest and most consistently accurate models are **Gradient Boosting Machines (GBMs)**.

Gradient Boosting is a powerful ensemble technique that builds a series of decision trees sequentially. It is the state-of-the-art for most problems involving tabular data and frequently wins machine learning competitions. Popular and highly optimized implementations include:

- **XGBoost**
- **LightGBM**
- **CatBoost**

These models are the strongest because they are incredibly effective at learning the complex, non-linear patterns and interactions that your EDA revealed are present in your dataset.

---

### Prompt 1.4

which of the implementations is best for my specific dataset? do all the features as input need to be nuumerical like for linear reggression or no?

### Response 1.4

For your specific dataset, **XGBoost** is the best implementation of Gradient Boosting to start with. It's the most widely used, robust, and consistently high-performing choice for datasets of your size and complexity.

Regarding input features, tree-based models like XGBoost are more flexible than Linear Regression. However, most standard implementations still require all input features to be numerical. This means your categorical feature, `created_wday`, must be converted into a numerical format. The standard method for this is **one-hot encoding**, which creates a new binary (0 or 1) column for each category.

---

## Sequence 2: EDA - Univariate Analysis of the Target Variable

This sequence focuses on the first step of the Exploratory Data Analysis (EDA): the univariate analysis of the target variable, `resolution_time`. It covers loading the data, visualizing the distribution, addressing severe skew with a log transformation, and justifying the methodological choices.

---

### Prompt 2.1

5.1. Univariate Analysis: Target Variable 
5.2. Bivariate Analysis: Predictors vs. Resolution Time 
5.3. Multivariate Analysis: Interactions Between Predictors 

these are the sections i would like for this eda section. lets work this out incrementally. first, i would like r code to lode all 4 cleaned data frames in rstudio:

### Response 2.1

Of course. Here is the R code to load your four cleaned `.rds` files into RStudio. This script will load each of the four cleaned datasets into its own data frame.

#### How This Code Works

- `library(tidyverse)`: This line loads the tidyverse suite of packages, which contains helpful functions for data analysis.
- `readRDS("filename.rds")`: This is the core function. It reads an R object saved in the `.rds` format from your disk.
- `cassandra_df <- ...`: We assign the loaded data from each file to a new variable (a data frame) with a descriptive name.

#### Important: Set Your Working Directory

Before running the script, you must tell R where your files are located. You can do this in one of two ways:

- **Using Code (Recommended)**: Add a `setwd()` command at the top of your script with the full path to the folder containing your `.rds` files. `setwd("path/to/your/folder")`
- **Using RStudio's Menu**: Go to `Session > Set Working Directory > Choose Directory...` and navigate to the correct folder.

---

### Prompt 2.2

first i would like you to update my script by creating a combined dataframe that combines the rows of all three datasets into one. the columns are the same accross all datasets.  

also i would like you to write the code necessary for 5.1. Univariate Analysis: Target Variable. it doesn't have to be the full code, just the initialize visualization in order for you to get feedback and provided next steps

### Response 2.2

Of course. I've updated your R script to combine the datasets and have added the initial code for the univariate analysis of the target variable.

#### Feedback and Next Steps

When you run this code, you will see two main outputs:

- **Summary Statistics**: Pay close attention to the difference between the **Mean** and the **Median**. You will see that the mean is much larger than the median. This is a classic sign of a right-skewed distribution.
- **Histogram**: The plot will visually confirm the skew. It will look like a steep drop-off with a very long "tail" extending to the right.

Your next step should be to address this skew. Most standard regression models work best when the target variable is normally distributed. Therefore, the logical next step is to apply a **log transformation** to `resolution_time` and re-examine the distribution.

Would you like me to add the code for the log transformation and the new visualizations?

---

### Prompt 2.3

these are the outputs. what observations can you make and what are the next actions or steps

### Response 2.3

Excellent. These outputs are very clear and tell a strong story. Here are the key observations and the necessary next steps.

#### Observations from Your Output

- **Extreme Right-Skew is Confirmed**: The histogram and the summary statistics both definitively show that the `resolution_time` data is heavily right-skewed.
- **Statistics**: The mean (109.1 days) is over 13 times larger than the median (8.1 days). This huge difference is a classic indicator that a small number of extreme values (outliers) are pulling the average way up.
- **Histogram**: The visualization makes this obvious. There is a massive bar on the far left, indicating the vast majority of bugs are fixed quickly, followed by a very long, flat "tail" to the right.
- **Implication for Modeling**: This skewed distribution is problematic for many predictive models, especially linear models. A heavily skewed target can lead to models that are inaccurate and make poor predictions.

#### Next Actions and Steps

The immediate goal is to handle this skewness. The standard and most effective approach for this is a **logarithmic transformation**. By taking the logarithm of the resolution time, we compress the large values much more than the small values. This pulls the long tail in and makes the distribution more symmetric. I can add the R code to perform this transformation and create new visualizations to see its effect.

---

### Prompt 2.4

shouldn't we remove outliers first or that should be done after the log transformation?

### Response 2.4

That's an excellent question. The standard and best practice is to **apply the log transformation first**, before you decide whether to remove any outliers.

#### Why Transform First?

- **The Transformation Changes What an "Outlier" Is**: In your original, skewed data, the points in the long tail look like extreme outliers. The log transformation's purpose is to pull in that tail. What seems like an outlier on the original scale might be a perfectly reasonable data point on the log scale.
- **You Risk Removing Valid Data**: Those long-resolution bugs are not errors; they are real, albeit infrequent, events. Removing them means you are throwing away valuable information. By transforming first, you preserve this information while reducing its ability to disproportionately influence the model.

#### The Correct Workflow

1. **Transform**: Apply the `log1p()` transformation to `resolution_time`.
2. **Re-visualize**: Create a new histogram and a box plot for the `log_resolution_time` variable.
3. **Re-assess**: Look at the new visualizations. The distribution will be much more symmetric. Now, you can check for outliers on this new scale.
4. **Decide**: In most cases, the transformation is sufficient. Unless you have a specific reason to believe a data point is an error, it's generally better to keep all the data.

In short, the log transformation is your main tool for handling extreme values, not outlier removal.

---

### Prompt 2.5

provided an update code to create the log transformed resolution time for each project as well as the combined and create the visualization to see the updates

### Response 2.5

Of course. Here is the updated R script. This version adds the `log_resolution_time` column and then creates two new visualizations:

- A histogram of the log-transformed data for all projects combined.
- A faceted histogram that shows the log-transformed distribution for each project individually, allowing for easy comparison.

#### What to Expect from the New Plots

- **Combined Log Histogram**: This plot will show a much more symmetric, bell-like shape compared to the original, confirming the transformation was successful.
- **Faceted Log Histogram**: This is the most insightful plot. It will show you three separate histograms, one for each project, so you can directly compare them:
    * Do all three projects have a similar shape after transformation?
    * Is the center (median) of the distribution roughly the same for all projects?
    * Does one project have a wider or narrower spread than the others?

These observations will be critical for your next steps, especially when thinking about building cross-project models.

---

### Prompt 2.6

why log(Resolution Time + 1)

### Response 2.6

We use `log(Resolution Time + 1)` to handle cases where the resolution time is **zero**.

#### The Mathematical Reason

The natural logarithm function, `log(x)`, is mathematically undefined for zero and negative numbers. If a bug is reported and resolved on the same day, its `resolution_time` could be 0. If we tried to calculate `log(0)`, R would produce `-Inf` (negative infinity), causing errors.

#### The Solution: Adding 1

By adding 1 to every value before taking the logarithm, we solve this problem:

- **If `resolution_time` = 0**: The calculation becomes `log(0 + 1) = log(1)`, which equals 0. This is a valid number that correctly represents the lowest possible value on the transformed scale.
- **If `resolution_time` > 0**: The `+1` has a very small impact, especially for larger numbers. The transformation still effectively compresses the scale and reduces skewness as intended.

In short, it's a standard way to apply a log transformation to data that might contain zeros. The R function `log1p(x)` is specifically designed to compute `log(1 + x)` accurately.

---

### Prompt 2.7

i would like summary statistics for the log transformed

### Response 2.7

Of course. I've added the code to your script to generate the summary statistics for the `log_resolution_time`. I placed it right after the original summary statistics so you can easily compare them.

When you run this, you will see two sets of summary statistics. You should notice that for the `log_resolution_time`, the **Mean** and **Median** values are much closer together, which numerically confirms that the distribution is more symmetric.

---

### Prompt 2.8

this is what i got. what is your analysis of this and what steps should i take from here. should i remove outliers?

### Response 2.8

Excellent, this is exactly what we wanted to see. The transformation was very successful.

#### Analysis of the Log-Transformed Data

- **The Distribution is Much More Symmetric**:
    - **From the statistics**: The mean (2.60) and median (2.21) are now very close. This is a strong numerical confirmation that we have corrected the extreme skew.
    - **From the histogram**: The plot now looks much more like a "hill" shape. The extremely long tail on the right is gone. The data is now much better behaved and suitable for modeling.

#### Should you remove outliers?

**No.** The log transformation has already done the heavy lifting of managing the extreme values. The points that are still at the higher end of the log scale represent the genuinely complex bugs that took a long time to fix. These are not errors; they are important data points. Removing them would mean you are telling your model to ignore the hardest cases.

#### Next Steps

You have successfully prepared your target variable. The univariate analysis for `resolution_time` is complete. The next logical step is to move on to **Section 5.2: Bivariate Analysis**. This is where you will start exploring the relationships between your predictor features and your newly transformed target variable, `log_resolution_time`, to answer questions like:

- Does a higher priority consistently lead to a lower `log_resolution_time`?
- Do bugs with more votes or comments get resolved faster?
- Does a more experienced reporter file bugs that get resolved faster?

We will do this by creating visualizations like box plots (for categorical predictors) and scatter plots (for numerical predictors).
