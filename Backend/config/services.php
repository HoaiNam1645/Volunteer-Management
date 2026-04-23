<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect_uri' => env('GOOGLE_REDIRECT_URI', 'postmessage'),
    ],

    /*
    |--------------------------------------------------------------------------
    | ML Trust Evaluation Service
    |--------------------------------------------------------------------------
    |
    | Cấu hình cho Python ML Service đánh giá độ tin cậy & rủi ro chiến dịch.
    |
    */

    'ml_trust' => [
        // Bật/tắt ML service (false = chỉ dùng fallback rule-based)
        'enabled' => env('ML_TRUST_ENABLED', true),

        // URL của Python FastAPI ML Service
        'url' => env('ML_TRUST_SERVICE_URL', 'http://127.0.0.1:8001'),

        // Timeout kết nối ML Service (giây)
        'timeout' => env('ML_TRUST_TIMEOUT', 10),

        // TTL cache kết quả evaluation (giây)
        'cache_ttl' => env('ML_TRUST_CACHE_TTL', 3600),

        // TTL cache cho volunteer evaluation (giây) - dài hơn vì ít thay đổi
        'volunteer_cache_ttl' => env('ML_TRUST_VOLUNTEER_CACHE_TTL', 21600),

        // Bật fallback rule-based khi ML service unavailable
        'fallback_enabled' => env('ML_TRUST_FALLBACK_ENABLED', true),

        // Internal API key dùng để Laravel gọi ML service an toàn hơn
        'internal_key' => env('ML_TRUST_INTERNAL_KEY'),
    ],

];
