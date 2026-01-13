# Overview of Android Health Connect Data Types

Android Health Connect organizes a wide array of health and fitness data into distinct categories, allowing for comprehensive management and sharing of information across different applications.

<details>
<summary>Here is the full list of supported data types, organized by category</summary>

### Body Measurement
> Measurements related to the physical state of the body.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Basal Metabolic Rate (BMR) | The number of calories the body burns at rest.                                                       | No           |
| Body Fat                   | The percentage of fat in the body.                                                                   | No           |
| Body Water Mass            | The total amount of water in the body.                                                               | No           |
| Bone Mass                  | The total mass of the skeletal system.                                                               | No           |
| Height                     | The user's height.                                                                                   | No           |
| Lean Body Mass             | The total mass of all non-fat tissues in the body.                                                   | No           |
| Weight                     | The user's body weight.                                                                              | No           |


</details>



<details>
<summary>The following data types are not yet supported</summary>
 
### Activity  
> Data related to the user's physical activities.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Active Calories Burned     | The number of calories burned during exercise or other physical activities.                          | No           |
| Activity Intensity         | The intensity level of physical activity.                                                            | No           |
| Distance                   | The distance covered during activities like walking, running, or cycling.                            | No           |
| Elevation Gained           | The total elevation climbed during an activity.                                                      | No           |
| Exercise                   | Details of specific exercise sessions, including type, duration, and other specifics.                | No           |
| Exercise Routes            | GPS route data recorded during exercise sessions.                                                    | No           |
| Floors Climbed             | The number of floors the user has climbed.                                                           | No           |
| Planned Exercise           | Scheduled or planned exercise sessions.                                                              | No           |
| Power                      | The instantaneous power generated during an activity, typically cycling, measured in watts.          | No           |
| Speed                      | The instantaneous or average speed during an activity.                                               | No           |
| Steps                      | The total number of steps taken throughout the day.                                                  | No           |
| Steps Cadence              | The number of steps per minute.                                                                      | No           |
| Total Calories Burned      | The total number of calories burned, combining basal metabolic rate and active calories.             | No           |
| VO2 Max                    | Maximum Oxygen Consumption - The maximum amount of oxygen the body can use during intense exercise.  | No           |
| Wheelchair Pushes          | The number of pushes for wheelchair users.                                                           | No           |
| Cycling Pedaling Cadence   | The number of pedal revolutions per minute while cycling.                                            | No           |

### Cycle Tracking
> Data related to the menstrual cycle.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Cervical Mucus             | The quality of cervical mucus (e.g., texture, appearance).                                           | No           |
| Menstruation Flow          | The heaviness of menstrual bleeding.                                                                 | No           |
| Ovulation Test             | The results of ovulation tests (e.g., positive, negative).                                           | No           |
| Sexual Activity            | Records of sexual activity.                                                                          | No           |
| Vaginal Spotting           | Records of spotting outside the menstrual period.                                                    | No           |


### Nutrition
> Data related to food and fluid intake. 

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Hydration                  | The amount of water consumed.                                                                        | No           |
| Nutrition                  | Detailed breakdown of calories and macro/micro nutrients consumed (e.g., protein, carbs, fats).      | No           |

### Sleep
> Data related to sleep patterns and quality.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Sleep                      | Details of sleep sessions, including start and end times, and sleep stages (e.g., light, deep, REM). | No           |


### Vitals
> Data on key health indicators and vital signs.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Blood Glucose              | The level of sugar in the blood.                                                                     | No           |
| Blood Pressure             | Systolic and diastolic blood pressure readings.                                                      | No           |
| Body Temperature           | The body's temperature.                                                                              | No           |
| Heart Rate                 | Instantaneous and resting heart rate values.                                                         | No           |
| Heart Rate Variability     | The variation in time intervals between heartbeats.                                                  | No           |
| Oxygen Saturation          | The oxygen saturation level in the blood (SpO2).                                                     | No           |
| Respiratory Rate           | The number of breaths taken per minute.                                                              | No           |
| Resting Heart Rate         | The heart rate measured when the body is at complete rest.                                           | No           |

### Mindfulness and Medical Data
> Data related to mental wellness and clinical/medical records.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Mindfulness                | Records of mindfulness or meditation sessions.                                                       | No           |


### Medical Data
> Clinical and medical records data.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Allergies & Intolerances   | Records of allergies and food/drug intolerances.                                                     | No           |
| Conditions                 | Medical conditions and diagnoses.                                                                    | No           |
| Laboratory Results         | Results from laboratory tests.                                                                       | No           |
| Medications                | Current and past medication records.                                                                 | No           |
| Personal Details           | Medical-related personal details.                                                                    | No           |
| Practitioner Details       | Information about healthcare practitioners.                                                          | No           |
| Pregnancy                  | Pregnancy-related health data.                                                                       | No           |
| Procedures                 | Records of medical procedures.                                                                       | No           |
| Social History             | Social history relevant to health (e.g., smoking, alcohol use).                                      | No           |
| Vaccines                   | Vaccination records.                                                                                 | No           |
| Visits                     | Records of healthcare visits.                                                                        | No           |
| Vital Signs (Medical)      | Clinical vital signs from medical records.                                                           | No           |


### System Permissions
> Permissions related to system-level health data access.

| Data Type                  | Description                                                                                          | Is Supported |
|----------------------------|------------------------------------------------------------------------------------------------------|--------------|
| Health Data in Background  | Permission to read health data in the background.                                                    | No           |

</details>

## Activity

This category includes data related to the user's physical activities.

* **Active Calories Burned**: The number of calories burned during exercise or other physical activities.
* **Distance**: The distance covered during activities like walking, running, or cycling.
* **Elevation Gained**: The total elevation climbed during an activity.
* **Exercise**: Details of specific exercise sessions, including type, duration, and other specifics (e.g., running, swimming, yoga).
* **Floors Climbed**: The number of floors the user has climbed.
* **Power**: The instantaneous power generated during an activity, typically cycling, measured in watts.
* **Speed**: The instantaneous or average speed during an activity.
* **Steps**: The total number of steps taken throughout the day.
* **Steps Cadence**: The number of steps per minute.
* **Total Calories** Burned: The total number of calories burned, combining basal metabolic rate and active calories.
* **VO2 Max**: Maximum Oxygen Consumption - The maximum amount of oxygen the body can use during intense exercise.
* **Wheelchair Pushes**: The number of pushes for wheelchair users.
* **Cycling Pedaling Cadence**: The number of pedal revolutions per minute while cycling.

## Body Measurement

This category covers measurements related to the physical state of the body.

* **Basal Metabolic Rate (BMR)**: The number of calories the body burns at rest.
* **Body Fat**: The percentage of fat in the body.
* **Bone Mass**: The total mass of the skeletal system.
* **Height**: The user's height.
* **Hip Circumference**: The measurement of the hip circumference.
* **Lean Body Mass**: The total mass of all non-fat tissues in the body.
* **Waist Circumference**: The measurement of the waist circumference.
* **Weight**: The user's body weight.

## Cycle Tracking

This category includes data related to the menstrual cycle.

* **Cervical Mucus**: The quality of cervical mucus (e.g., texture, appearance).
* **Menstruation Flow**: The heaviness of menstrual bleeding.
* **Ovulation Test**: The results of ovulation tests (e.g., positive, negative).
* **Sexual Activity**: Records of sexual activity.
* **Vaginal Spotting**: Records of spotting outside the menstrual period.

## Nutrition

This category includes data related to food and fluid intake.

* **Hydration**: The amount of water consumed.
* **Nutrition**: Detailed breakdown of calories and macro/micro nutrients consumed (e.g., protein, carbohydrates, fat, vitamins, minerals).

## Sleep

This category contains data related to sleep patterns and quality.

* **Sleep**: Details of sleep sessions, including start and end times, and sleep stages (e.g., light, deep, REM).

## Vitals

This category includes data on key health indicators and vital signs.

* **Blood Glucose**: The level of sugar in the blood.
* **Blood Pressure**: Systolic and diastolic blood pressure readings.
* **Body Temperature**: The body's temperature.
* **Heart Rate**: Instantaneous and resting heart rate values.
* **Oxygen Saturation**: The oxygen saturation level in the blood (SpO2).
* **Respiratory Rate**: The number of breaths taken per minute.
* **Resting Heart Rate**: The heart rate measured when the body is at complete rest.


