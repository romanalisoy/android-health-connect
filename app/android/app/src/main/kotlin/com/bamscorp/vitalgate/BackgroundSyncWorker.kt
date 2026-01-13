package com.bamscorp.vitalgate

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit

class BackgroundSyncWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    companion object {
        private const val TAG = "BackgroundSyncWorker"
        private const val WORK_NAME = "health_background_sync"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // Data types to sync (Body Measurements)
        private val SYNC_DATA_TYPES = listOf(
            "weight", "height", "body_fat", "body_water_mass",
            "bone_mass", "lean_body_mass", "basal_metabolic_rate"
        )

        // History range options in days
        private val HISTORY_RANGE_DAYS = mapOf(
            "1 day" to 1,
            "2 days" to 2,
            "1 week" to 7,
            "15 days" to 15,
            "21 days" to 21,
            "30 days" to 30
        )

        // Sync interval options in hours
        private val SYNC_INTERVAL_HOURS = mapOf(
            "Every 1 hour" to 1L,
            "Every 2 hours" to 2L,
            "Every 6 hours" to 6L,
            "Every 12 hours" to 12L,
            "Once a day" to 24L
        )

        fun schedule(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val intervalKey = prefs.getString("flutter.sync_interval", "Every 1 hour") ?: "Every 1 hour"
            val intervalHours = SYNC_INTERVAL_HOURS[intervalKey] ?: 1L

            Log.d(TAG, "Scheduling background sync every $intervalHours hours")

            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .setRequiresBatteryNotLow(true)
                .build()

            val syncRequest = PeriodicWorkRequestBuilder<BackgroundSyncWorker>(
                intervalHours, TimeUnit.HOURS
            )
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    WorkRequest.MIN_BACKOFF_MILLIS,
                    TimeUnit.MILLISECONDS
                )
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                syncRequest
            )

            Log.d(TAG, "Background sync scheduled successfully")
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "Background sync cancelled")
        }
    }

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        Log.d(TAG, "Starting background sync...")

        try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Get credentials
            val baseUrl = prefs.getString("flutter.base_url", null)
            val accessToken = prefs.getString("flutter.access_token", null)

            if (baseUrl == null || accessToken == null) {
                Log.e(TAG, "Not authenticated, skipping sync")
                return@withContext Result.success()
            }

            // Get history range
            val rangeKey = prefs.getString("flutter.history_range", "1 week") ?: "1 week"
            val days = HISTORY_RANGE_DAYS[rangeKey] ?: 7

            val endTime = Instant.now()
            val startTime = endTime.minus(days.toLong(), ChronoUnit.DAYS)

            Log.d(TAG, "Syncing data from $startTime to $endTime")

            // Check Health Connect availability
            val healthConnectClient = try {
                HealthConnectClient.getOrCreate(applicationContext)
            } catch (e: Exception) {
                Log.e(TAG, "Health Connect not available: ${e.message}")
                return@withContext Result.failure()
            }

            var uploadedCount = 0
            var failedCount = 0

            // Sync each data type
            for (dataType in SYNC_DATA_TYPES) {
                try {
                    val data = readHealthData(healthConnectClient, dataType, startTime, endTime)
                    if (data.isNotEmpty()) {
                        val recordType = getRecordType(dataType)
                        val success = uploadData(baseUrl, accessToken, recordType, data)
                        if (success) {
                            uploadedCount += data.size
                            Log.d(TAG, "Uploaded ${data.size} $dataType records")
                        } else {
                            failedCount += data.size
                            Log.e(TAG, "Failed to upload $dataType records")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error syncing $dataType: ${e.message}")
                    failedCount++
                }
            }

            // Log sync result
            logSyncResult(prefs, uploadedCount, failedCount)

            Log.d(TAG, "Background sync completed: $uploadedCount uploaded, $failedCount failed")
            return@withContext Result.success()

        } catch (e: Exception) {
            Log.e(TAG, "Background sync failed: ${e.message}", e)
            return@withContext Result.retry()
        }
    }

    private suspend fun readHealthData(
        client: HealthConnectClient,
        dataType: String,
        startTime: Instant,
        endTime: Instant
    ): List<Map<String, Any>> {
        val timeRangeFilter = TimeRangeFilter.between(startTime, endTime)

        return when (dataType) {
            "weight" -> {
                val request = ReadRecordsRequest(WeightRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "weight" to record.weight.inKilograms
                    )
                }
            }
            "height" -> {
                val request = ReadRecordsRequest(HeightRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "height" to record.height.inMeters
                    )
                }
            }
            "body_fat" -> {
                val request = ReadRecordsRequest(BodyFatRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "percentage" to record.percentage.value
                    )
                }
            }
            "body_water_mass" -> {
                val request = ReadRecordsRequest(BodyWaterMassRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "bone_mass" -> {
                val request = ReadRecordsRequest(BoneMassRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "lean_body_mass" -> {
                val request = ReadRecordsRequest(LeanBodyMassRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "mass" to record.mass.inKilograms
                    )
                }
            }
            "basal_metabolic_rate" -> {
                val request = ReadRecordsRequest(BasalMetabolicRateRecord::class, timeRangeFilter)
                val response = client.readRecords(request)
                response.records.map { record ->
                    mapOf(
                        "id" to record.metadata.id,
                        "dataOrigin" to record.metadata.dataOrigin.packageName,
                        "time" to record.time.toEpochMilli(),
                        "basalMetabolicRate" to record.basalMetabolicRate.inKilocaloriesPerDay
                    )
                }
            }
            else -> emptyList()
        }
    }

    private fun getRecordType(dataType: String): String {
        return when (dataType) {
            "weight" -> "Weight"
            "height" -> "Height"
            "body_fat" -> "BodyFat"
            "body_water_mass" -> "BodyWaterMass"
            "bone_mass" -> "BoneMass"
            "lean_body_mass" -> "LeanBodyMass"
            "basal_metabolic_rate" -> "BasalMetabolicRate"
            else -> dataType
        }
    }

    private fun uploadData(
        baseUrl: String,
        accessToken: String,
        recordType: String,
        data: List<Map<String, Any>>
    ): Boolean {
        try {
            val jsonArray = JSONArray()
            for (record in data) {
                val jsonObject = JSONObject()
                for ((key, value) in record) {
                    jsonObject.put(key, value)
                }
                jsonArray.put(jsonObject)
            }

            val body = JSONObject().put("data", jsonArray).toString()
            val mediaType = "application/json; charset=utf-8".toMediaType()

            val request = Request.Builder()
                .url("$baseUrl/api/v1/health/$recordType")
                .addHeader("Authorization", "Bearer $accessToken")
                .addHeader("Content-Type", "application/json")
                .post(body.toRequestBody(mediaType))
                .build()

            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful

            if (!success) {
                Log.e(TAG, "Upload failed: ${response.code} - ${response.body?.string()}")
            }

            response.close()
            return success

        } catch (e: Exception) {
            Log.e(TAG, "Upload error: ${e.message}", e)
            return false
        }
    }

    private fun logSyncResult(prefs: SharedPreferences, successCount: Int, failedCount: Int) {
        try {
            val historyKey = "flutter.sync_history_logs"
            val existingJson = prefs.getString(historyKey, "[]") ?: "[]"
            val historyArray = JSONArray(existingJson)

            val entry = JSONObject().apply {
                put("id", java.util.UUID.randomUUID().toString())
                put("timestamp", System.currentTimeMillis())
                put("successCount", successCount)
                put("failedCount", failedCount)
                put("errors", JSONArray())
                put("isBackgroundSync", true)
            }

            historyArray.put(entry)

            // Keep only last 100 entries
            while (historyArray.length() > 100) {
                historyArray.remove(0)
            }

            prefs.edit().putString(historyKey, historyArray.toString()).apply()

        } catch (e: Exception) {
            Log.e(TAG, "Error logging sync result: ${e.message}")
        }
    }
}
