<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED);

// Logging configuration
$logFile = 'unsubscription_log.txt';
$maxLogSize = 5 * 1024 * 1024; // 5MB

/**
 * Log a message to file with timestamp
 * 
 * @param string $level Log level (INFO, ERROR, WARNING, DEBUG)
 * @param string $message Message to log
 * @param array $context Additional context data
 */
function logMessage($level, $message, $context = []) {
    global $logFile, $maxLogSize;
    
    $timestamp = date('Y-m-d H:i:s');
    $contextStr = !empty($context) ? ' | ' . json_encode($context) : '';
    $logEntry = "[$timestamp] [$level] $message$contextStr\n";
    
    // Check if log file size exceeds limit, rotate if necessary
    if (file_exists($logFile) && filesize($logFile) > $maxLogSize) {
        $backupFile = $logFile . '.backup.' . date('Y-m-d-H-i-s');
        rename($logFile, $backupFile);
    }
    
    file_put_contents($logFile, $logEntry, FILE_APPEND);
}

function callBdapps(string $url, array $requestData): array {
    $requestJson = json_encode($requestData);
    if ($requestJson === false) {
        $error = 'Failed to JSON encode request data';
        logMessage('ERROR', $error);
        return ['ok' => false, 'error' => $error];
    }

    $ch = curl_init();
    if ($ch === false) {
        $error = 'Unable to initialize cURL';
        logMessage('ERROR', $error);
        return ['ok' => false, 'error' => $error];
    }

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        "Content-Type: application/json",
        "Content-Length: " . strlen($requestJson)
    ));
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);

    logMessage('DEBUG', 'Sending BDApps request', ['url' => $url]);

    $responseJson = curl_exec($ch);
    $curlError = curl_error($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($responseJson === false) {
        $error = "cURL request failed: $curlError (HTTP $httpCode)";
        logMessage('ERROR', $error, ['url' => $url]);
        return ['ok' => false, 'error' => $error];
    }

    // Check if response is HTML (error page)
    if (stripos($responseJson, '<html') !== false || stripos($responseJson, '<!DOCTYPE') !== false) {
        $error = "BDApps returned HTML error page (HTTP $httpCode)";
        logMessage('ERROR', $error, ['http_code' => $httpCode, 'response_preview' => substr($responseJson, 0, 200)]);
        return ['ok' => false, 'error' => $error];
    }

    $response = json_decode($responseJson, true);
    if (!is_array($response)) {
        $error = "Invalid JSON response from BDApps";
        logMessage('ERROR', $error, ['response' => substr($responseJson, 0, 200)]);
        return ['ok' => false, 'error' => $error];
    }

    logMessage('DEBUG', 'BDApps response received', ['status_code' => $response['statusCode'] ?? 'unknown', 'http_code' => $httpCode]);
    return ['ok' => true, 'data' => $response, 'raw' => $responseJson];
}

logMessage('INFO', 'Unsubscription request started');

$rawMobile = trim($_POST['user_mobile'] ?? $_POST['subscriberId'] ?? '');
if ($rawMobile === '') {
    $error = 'Mobile number is required';
    logMessage('WARNING', $error);
    echo json_encode(['error' => 'Mobile number required']);
    exit;
}

logMessage('DEBUG', 'Phone number received', ['phone_raw' => $rawMobile]);

$digits = preg_replace('/\D+/', '', $rawMobile);
if (strlen($digits) === 13 && substr($digits, 0, 2) === '88') {
    $digits = substr($digits, 2);
}

if (strlen($digits) !== 11 || $digits[0] !== '0') {
    $error = "Invalid mobile format: expected 11 digits starting with 0, got " . strlen($digits) . " digits";
    logMessage('WARNING', $error, ['phone_digits' => $digits]);
    echo json_encode(['error' => 'Invalid mobile number format. Please use format: 018XXXXXXXX or 880XXXXXXXXXX']);
    exit;
}

$subscriberId = 'tel:88' . $digits;
logMessage('DEBUG', 'Phone number normalized', ['subscriber_id' => $subscriberId]);

// BDApps credentials
$appId = 'APP_136200';
$password = '2e4c79447154658bf1751f43c193a5e5';

$requestData = array(
    'applicationId' => $appId,
    'password' => $password,
    'subscriberId' => $subscriberId,
    'version' => '1.0',
    'action' => '0',
);

logMessage('DEBUG', 'Calling BDApps unsubscription endpoint', ['subscriber_id' => $subscriberId]);

$result = callBdapps('https://developer.bdapps.com/subscription/send', $requestData);

if (!$result['ok']) {
    $error = $result['error'];
    logMessage('ERROR', 'BDApps call failed', ['subscriber_id' => $subscriberId, 'error' => $error]);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to process unsubscription request. Please try again later.',
        'subscriberId' => $subscriberId,
        'action' => '0',
    ]);
    exit;
}

$response = $result['data'];
$statusCode = strtoupper((string)($response['statusCode'] ?? ''));
$subscriptionStatus = $response['subscriptionStatus'] ?? 'UNKNOWN';

$success =
    $statusCode === 'S1000' ||
    strtoupper((string)$subscriptionStatus) === 'UNREGISTERED';

if ($success) {
    logMessage('INFO', 'Unsubscription successful', [
        'subscriber_id' => $subscriberId,
        'status_code' => $statusCode,
        'subscription_status' => $subscriptionStatus
    ]);
} else {
    logMessage('WARNING', 'Unsubscription request failed', [
        'subscriber_id' => $subscriberId,
        'status_code' => $statusCode,
        'status_detail' => $response['statusDetail'] ?? 'Unknown error',
        'subscription_status' => $subscriptionStatus
    ]);
}

echo json_encode([
    'success' => $success,
    'message' => $success ? 'Unsubscription successful' : 'Unsubscription failed. Please try again.',
    'subscriberId' => $subscriberId,
    'action' => '0',
    'version' => '1.0',
    'statusCode' => $response['statusCode'] ?? null,
    'statusDetail' => $response['statusDetail'] ?? null,
    'subscriptionStatus' => $subscriptionStatus,
]);

?>
