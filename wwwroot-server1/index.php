<?php
// Aktivera felrapportering för att visa alla fel och varningar
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Inkludera konfigurationsfilen
$configFile = 'config.php';
if (!file_exists($configFile)) {
    die("Configuration file not found: $configFile");
}

$config = include $configFile;

// Kontrollera att konfigurationsdata finns
if (!isset($config['servername'], $config['username'], $config['password'], $config['dbname'])) {
    die("Configuration file is missing required fields.");
}

// Extrahera databasuppgifterna från konfigurationen
$servername = $config['servername'];
$username = $config['username'];
$password = $config['password'];
$dbname = $config['dbname'];

// Skapa anslutningen
$conn = new mysqli($servername, $username, $password, $dbname);

// Kontrollera anslutningen
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error . " (Error Code: " . $conn->connect_errno . ")");
}

echo "Connected successfully to database '$dbname' on server '$servername'.<br>";

// Här kan du lägga till fler tester eller debug-utskrifter
// Till exempel: kontrollera databasens version
$version = $conn->server_info;
echo "MySQL Server Version: $version<br>";

// Stäng anslutningen när du är klar
$conn->close();
echo "Connection closed successfully. WEB-SERVER-1";
?>
