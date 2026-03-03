<?php

$vendorAutoload = dirname(__DIR__) . '/vendor/autoload.php';
if (is_file($vendorAutoload)) {
    require_once $vendorAutoload;
}

$sources = [
    dirname(__DIR__) . '/src/Config.php',
    dirname(__DIR__) . '/src/Errors.php',
    dirname(__DIR__) . '/src/Protocol.php',
    dirname(__DIR__) . '/src/Scram.php',
    dirname(__DIR__) . '/src/Connection.php',
    dirname(__DIR__) . '/src/Sql.php',
    dirname(__DIR__) . '/src/Statement.php',
    dirname(__DIR__) . '/src/ResultStream.php',
    dirname(__DIR__) . '/src/ScratchBirdPDO.php',
];

foreach ($sources as $source) {
    if (is_file($source)) {
        require_once $source;
    }
}
