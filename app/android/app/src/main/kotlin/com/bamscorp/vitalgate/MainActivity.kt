package com.bamscorp.vitalgate

import android.os.Bundle
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.time.Instant
import kotlin.reflect.KClass

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.bamscorp.vitalgate/health_connect"
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var healthConnectClient: HealthConnectClient

    // Permission definitions with display names and categories
    private val permissionDefinitions = listOf(
        // Heart & Vitals
        PermissionDef("heart_rate", "Heart Rate", "Heart & Vitals", HealthPermission.getReadPermission(HeartRateRecord::class)),
        PermissionDef("heart_rate_variability", "Heart Rate Variability", "Heart & Vitals", HealthPermission.getReadPermission(HeartRateVariabilityRmssdRecord::class)),
        PermissionDef("resting_heart_rate", "Resting Heart Rate", "Heart & Vitals", HealthPermission.getReadPermission(RestingHeartRateRecord::class)),
        PermissionDef("blood_pressure", "Blood Pressure", "Heart & Vitals", HealthPermission.getReadPermission(BloodPressureRecord::class)),
        PermissionDef("blood_oxygen", "Blood Oxygen", "Heart & Vitals", HealthPermission.getReadPermission(OxygenSaturationRecord::class)),
        PermissionDef("respiratory_rate", "Respiratory Rate", "Heart & Vitals", HealthPermission.getReadPermission(RespiratoryRateRecord::class)),
        PermissionDef("blood_glucose", "Blood Glucose", "Heart & Vitals", HealthPermission.getReadPermission(BloodGlucoseRecord::class)),
        PermissionDef("body_temperature", "Body Temperature", "Heart & Vitals", HealthPermission.getReadPermission(BodyTemperatureRecord::class)),
        PermissionDef("basal_body_temperature", "Basal Body Temperature", "Heart & Vitals", HealthPermission.getReadPermission(BasalBodyTemperatureRecord::class)),
        PermissionDef("vo2_max", "VO2 Max", "Heart & Vitals", HealthPermission.getReadPermission(Vo2MaxRecord::class)),

        // Physical Activity
        PermissionDef("steps", "Steps", "Physical Activity", HealthPermission.getReadPermission(StepsRecord::class)),
        PermissionDef("distance", "Distance", "Physical Activity", HealthPermission.getReadPermission(DistanceRecord::class)),
        PermissionDef("active_calories", "Active Calories Burned", "Physical Activity", HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class)),
        PermissionDef("total_calories", "Total Calories Burned", "Physical Activity", HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class)),
        PermissionDef("floors_climbed", "Floors Climbed", "Physical Activity", HealthPermission.getReadPermission(FloorsClimbedRecord::class)),
        PermissionDef("elevation_gained", "Elevation Gained", "Physical Activity", HealthPermission.getReadPermission(ElevationGainedRecord::class)),
        PermissionDef("speed", "Speed", "Physical Activity", HealthPermission.getReadPermission(SpeedRecord::class)),
        PermissionDef("power", "Power", "Physical Activity", HealthPermission.getReadPermission(PowerRecord::class)),
        PermissionDef("exercise", "Exercise Sessions", "Physical Activity", HealthPermission.getReadPermission(ExerciseSessionRecord::class)),
        PermissionDef("wheelchair_pushes", "Wheelchair Pushes", "Physical Activity", HealthPermission.getReadPermission(WheelchairPushesRecord::class)),
        PermissionDef("planned_exercise", "Training Plans", "Physical Activity", HealthPermission.getReadPermission(PlannedExerciseSessionRecord::class)),

        // Body Measurements
        PermissionDef("weight", "Weight", "Body Measurements", HealthPermission.getReadPermission(WeightRecord::class)),
        PermissionDef("height", "Height", "Body Measurements", HealthPermission.getReadPermission(HeightRecord::class)),
        PermissionDef("body_fat", "Body Fat", "Body Measurements", HealthPermission.getReadPermission(BodyFatRecord::class)),
        PermissionDef("body_water_mass", "Body Water Mass", "Body Measurements", HealthPermission.getReadPermission(BodyWaterMassRecord::class)),
        PermissionDef("bone_mass", "Bone Mass", "Body Measurements", HealthPermission.getReadPermission(BoneMassRecord::class)),
        PermissionDef("lean_body_mass", "Lean Body Mass", "Body Measurements", HealthPermission.getReadPermission(LeanBodyMassRecord::class)),
        PermissionDef("basal_metabolic_rate", "Basal Metabolic Rate", "Body Measurements", HealthPermission.getReadPermission(BasalMetabolicRateRecord::class)),
        PermissionDef("skin_temperature", "Skin Temperature", "Body Measurements", HealthPermission.getReadPermission(SkinTemperatureRecord::class)),

        // Sleep
        PermissionDef("sleep", "Sleep Sessions", "Sleep Analysis", HealthPermission.getReadPermission(SleepSessionRecord::class)),

        // Nutrition
        PermissionDef("hydration", "Water / Hydration", "Nutrition", HealthPermission.getReadPermission(HydrationRecord::class)),
        PermissionDef("nutrition", "Nutrition / Macros", "Nutrition", HealthPermission.getReadPermission(NutritionRecord::class)),

        // Cycle Tracking
        PermissionDef("menstruation_flow", "Menstruation Flow", "Cycle Tracking", HealthPermission.getReadPermission(MenstruationFlowRecord::class)),
        PermissionDef("menstruation_period", "Menstruation Period", "Cycle Tracking", HealthPermission.getReadPermission(MenstruationPeriodRecord::class)),
        PermissionDef("cervical_mucus", "Cervical Mucus", "Cycle Tracking", HealthPermission.getReadPermission(CervicalMucusRecord::class)),
        PermissionDef("ovulation_test", "Ovulation Test", "Cycle Tracking", HealthPermission.getReadPermission(OvulationTestRecord::class)),
        PermissionDef("sexual_activity", "Sexual Activity", "Cycle Tracking", HealthPermission.getReadPermission(SexualActivityRecord::class)),
        PermissionDef("intermenstrual_bleeding", "Intermenstrual Bleeding", "Cycle Tracking", HealthPermission.getReadPermission(IntermenstrualBleedingRecord::class)),
    )

    // All Health Connect permissions
    private val allPermissions = buildSet {
        permissionDefinitions.forEach { add(it.permission) }
        add(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)
    }

    data class PermissionDef(
        val id: String,
        val name: String,
        val category: String,
        val permission: String
    )

    private val requestPermissionActivityContract = PermissionController.createRequestPermissionResultContract()

    private val requestPermissions = registerForActivityResult(requestPermissionActivityContract) { granted ->
        pendingResult?.let { result ->
            if (granted.containsAll(allPermissions)) {
                result.success(mapOf("success" to true, "message" to "All permissions granted"))
            } else {
                val grantedCount = granted.size
                val totalCount = allPermissions.size
                result.success(mapOf(
                    "success" to false,
                    "message" to "Granted $grantedCount of $totalCount permissions",
                    "grantedCount" to grantedCount,
                    "totalCount" to totalCount
                ))
            }
            pendingResult = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            healthConnectClient = HealthConnectClient.getOrCreate(this)
        } catch (e: Exception) {
            // Health Connect not available
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAvailability" -> {
                    val status = HealthConnectClient.getSdkStatus(this)
                    when (status) {
                        HealthConnectClient.SDK_AVAILABLE -> result.success("available")
                        HealthConnectClient.SDK_UNAVAILABLE -> result.success("unavailable")
                        HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> result.success("needs_update")
                        else -> result.success("unknown")
                    }
                }
                "requestAllPermissions" -> {
                    try {
                        val status = HealthConnectClient.getSdkStatus(this)
                        if (status != HealthConnectClient.SDK_AVAILABLE) {
                            result.success(mapOf("success" to false, "message" to "Health Connect not available. Status: $status"))
                            return@setMethodCallHandler
                        }

                        pendingResult = result
                        requestPermissions.launch(allPermissions)
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "message" to "Error: ${e.message}"))
                    }
                }
                "checkPermissions" -> {
                    try {
                        val status = HealthConnectClient.getSdkStatus(this)
                        if (status != HealthConnectClient.SDK_AVAILABLE) {
                            result.success(mapOf("granted" to false, "count" to 0))
                            return@setMethodCallHandler
                        }

                        lifecycleScope.launch {
                            try {
                                val granted = healthConnectClient.permissionController.getGrantedPermissions()
                                val allGranted = granted.containsAll(allPermissions)
                                result.success(mapOf(
                                    "granted" to allGranted,
                                    "count" to granted.intersect(allPermissions).size,
                                    "total" to allPermissions.size
                                ))
                            } catch (e: Exception) {
                                result.success(mapOf("granted" to false, "count" to 0, "error" to e.message))
                            }
                        }
                    } catch (e: Exception) {
                        result.success(mapOf("granted" to false, "count" to 0, "error" to e.message))
                    }
                }
                "getPermissionsList" -> {
                    try {
                        val status = HealthConnectClient.getSdkStatus(this)
                        if (status != HealthConnectClient.SDK_AVAILABLE) {
                            result.success(mapOf("success" to false, "permissions" to listOf<Map<String, Any>>()))
                            return@setMethodCallHandler
                        }

                        lifecycleScope.launch {
                            try {
                                val granted = healthConnectClient.permissionController.getGrantedPermissions()

                                val permissionsList = permissionDefinitions.map { def ->
                                    mapOf(
                                        "id" to def.id,
                                        "name" to def.name,
                                        "category" to def.category,
                                        "granted" to granted.contains(def.permission)
                                    )
                                }

                                // Add background permission
                                val backgroundGranted = granted.contains(HealthPermission.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND)
                                val fullList = permissionsList + mapOf(
                                    "id" to "background_read",
                                    "name" to "Background Data Access",
                                    "category" to "System",
                                    "granted" to backgroundGranted
                                )

                                result.success(mapOf(
                                    "success" to true,
                                    "permissions" to fullList
                                ))
                            } catch (e: Exception) {
                                result.success(mapOf("success" to false, "error" to e.message, "permissions" to listOf<Map<String, Any>>()))
                            }
                        }
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "error" to e.message, "permissions" to listOf<Map<String, Any>>()))
                    }
                }
                "getHealthData" -> {
                    try {
                        val type = call.argument<String>("type") ?: ""
                        val startTime = call.argument<Long>("startTime") ?: 0L
                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()

                        val status = HealthConnectClient.getSdkStatus(this)
                        if (status != HealthConnectClient.SDK_AVAILABLE) {
                            result.success(mapOf("success" to false, "data" to listOf<Map<String, Any>>()))
                            return@setMethodCallHandler
                        }

                        lifecycleScope.launch {
                            try {
                                val data = readHealthData(type, startTime, endTime)
                                result.success(mapOf("success" to true, "data" to data))
                            } catch (e: Exception) {
                                result.success(mapOf("success" to false, "error" to e.message, "data" to listOf<Map<String, Any>>()))
                            }
                        }
                    } catch (e: Exception) {
                        result.success(mapOf("success" to false, "error" to e.message, "data" to listOf<Map<String, Any>>()))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private suspend fun readHealthData(type: String, startTimeMs: Long, endTimeMs: Long): List<Map<String, Any?>> {
        val startTime = Instant.ofEpochMilli(startTimeMs)
        val endTime = Instant.ofEpochMilli(endTimeMs)
        val timeRangeFilter = TimeRangeFilter.between(startTime, endTime)

        return when (type) {
            "heart_rate" -> {
                val request = ReadRecordsRequest(HeartRateRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.flatMap { record ->
                    record.samples.map { sample ->
                        mapOf(
                            "time" to sample.time.toEpochMilli(),
                            "bpm" to sample.beatsPerMinute
                        )
                    }
                }
            }
            "heart_rate_variability" -> {
                val request = ReadRecordsRequest(HeartRateVariabilityRmssdRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "heartRateVariabilityMillis" to record.heartRateVariabilityMillis
                    )
                }
            }
            "resting_heart_rate" -> {
                val request = ReadRecordsRequest(RestingHeartRateRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "bpm" to record.beatsPerMinute
                    )
                }
            }
            "blood_pressure" -> {
                val request = ReadRecordsRequest(BloodPressureRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "systolic" to record.systolic.inMillimetersOfMercury,
                        "diastolic" to record.diastolic.inMillimetersOfMercury
                    )
                }
            }
            "blood_oxygen" -> {
                val request = ReadRecordsRequest(OxygenSaturationRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "percentage" to record.percentage.value
                    )
                }
            }
            "respiratory_rate" -> {
                val request = ReadRecordsRequest(RespiratoryRateRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "rate" to record.rate
                    )
                }
            }
            "blood_glucose" -> {
                val request = ReadRecordsRequest(BloodGlucoseRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "level" to record.level.inMillimolesPerLiter
                    )
                }
            }
            "body_temperature" -> {
                val request = ReadRecordsRequest(BodyTemperatureRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "temperature" to record.temperature.inCelsius
                    )
                }
            }
            "basal_body_temperature" -> {
                val request = ReadRecordsRequest(BasalBodyTemperatureRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "temperature" to record.temperature.inCelsius
                    )
                }
            }
            "vo2_max" -> {
                val request = ReadRecordsRequest(Vo2MaxRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "vo2Max" to record.vo2MillilitersPerMinuteKilogram
                    )
                }
            }
            "steps" -> {
                val request = ReadRecordsRequest(StepsRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "count" to record.count
                    )
                }
            }
            "distance" -> {
                val request = ReadRecordsRequest(DistanceRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "distance" to record.distance.inMeters
                    )
                }
            }
            "active_calories" -> {
                val request = ReadRecordsRequest(ActiveCaloriesBurnedRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "energy" to record.energy.inKilocalories
                    )
                }
            }
            "total_calories" -> {
                val request = ReadRecordsRequest(TotalCaloriesBurnedRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "energy" to record.energy.inKilocalories
                    )
                }
            }
            "floors_climbed" -> {
                val request = ReadRecordsRequest(FloorsClimbedRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "floors" to record.floors
                    )
                }
            }
            "elevation_gained" -> {
                val request = ReadRecordsRequest(ElevationGainedRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "elevation" to record.elevation.inMeters
                    )
                }
            }
            "speed" -> {
                val request = ReadRecordsRequest(SpeedRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.flatMap { record ->
                    record.samples.map { sample ->
                        mapOf(
                            "time" to sample.time.toEpochMilli(),
                            "speed" to sample.speed.inMetersPerSecond
                        )
                    }
                }
            }
            "power" -> {
                val request = ReadRecordsRequest(PowerRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.flatMap { record ->
                    record.samples.map { sample ->
                        mapOf(
                            "time" to sample.time.toEpochMilli(),
                            "power" to sample.power.inWatts
                        )
                    }
                }
            }
            "exercise" -> {
                val request = ReadRecordsRequest(ExerciseSessionRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "exerciseType" to record.exerciseType,
                        "title" to record.title,
                        "notes" to record.notes
                    )
                }
            }
            "wheelchair_pushes" -> {
                val request = ReadRecordsRequest(WheelchairPushesRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "count" to record.count
                    )
                }
            }
            "weight" -> {
                val request = ReadRecordsRequest(WeightRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "weight" to record.weight.inKilograms
                    )
                }
            }
            "height" -> {
                val request = ReadRecordsRequest(HeightRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "height" to record.height.inMeters
                    )
                }
            }
            "body_fat" -> {
                val request = ReadRecordsRequest(BodyFatRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "percentage" to record.percentage.value
                    )
                }
            }
            "body_water_mass" -> {
                val request = ReadRecordsRequest(BodyWaterMassRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "bone_mass" -> {
                val request = ReadRecordsRequest(BoneMassRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "lean_body_mass" -> {
                val request = ReadRecordsRequest(LeanBodyMassRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "basal_metabolic_rate" -> {
                val request = ReadRecordsRequest(BasalMetabolicRateRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "basalMetabolicRate" to record.basalMetabolicRate.inKilocaloriesPerDay
                    )
                }
            }
            "sleep" -> {
                val request = ReadRecordsRequest(SleepSessionRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "title" to record.title,
                        "notes" to record.notes,
                        "stages" to record.stages.map { stage ->
                            mapOf(
                                "startTime" to stage.startTime.toEpochMilli(),
                                "endTime" to stage.endTime.toEpochMilli(),
                                "stage" to stage.stage
                            )
                        }
                    )
                }
            }
            "hydration" -> {
                val request = ReadRecordsRequest(HydrationRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "volume" to record.volume.inLiters
                    )
                }
            }
            "nutrition" -> {
                val request = ReadRecordsRequest(NutritionRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli(),
                        "name" to record.name,
                        "energy" to record.energy?.inKilocalories,
                        "protein" to record.protein?.inGrams,
                        "totalCarbohydrate" to record.totalCarbohydrate?.inGrams,
                        "totalFat" to record.totalFat?.inGrams
                    )
                }
            }
            "menstruation_flow" -> {
                val request = ReadRecordsRequest(MenstruationFlowRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "flow" to record.flow
                    )
                }
            }
            "menstruation_period" -> {
                val request = ReadRecordsRequest(MenstruationPeriodRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "startTime" to record.startTime.toEpochMilli(),
                        "endTime" to record.endTime.toEpochMilli()
                    )
                }
            }
            "cervical_mucus" -> {
                val request = ReadRecordsRequest(CervicalMucusRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "appearance" to record.appearance,
                        "sensation" to record.sensation
                    )
                }
            }
            "ovulation_test" -> {
                val request = ReadRecordsRequest(OvulationTestRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "result" to record.result
                    )
                }
            }
            "sexual_activity" -> {
                val request = ReadRecordsRequest(SexualActivityRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli(),
                        "protectionUsed" to record.protectionUsed
                    )
                }
            }
            "intermenstrual_bleeding" -> {
                val request = ReadRecordsRequest(IntermenstrualBleedingRecord::class, timeRangeFilter)
                val response = healthConnectClient.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "time" to record.time.toEpochMilli()
                    )
                }
            }
            else -> emptyList()
        }
    }
}
