<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$users = App\Models\NguoiDung::all(['id', 'ho_ten', 'email', 'vai_tro']);
foreach($users as $u) {
    echo $u->id . " | " . $u->ho_ten . " | " . $u->email . " | " . $u->vai_tro . "\n";
}
