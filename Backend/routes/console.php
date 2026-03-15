<?php

use App\Console\Commands\SendParticipationReminderCommand;
use App\Console\Commands\SendCampaignOwnerReminderCommand;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command(SendParticipationReminderCommand::class)->daily();
Schedule::command(SendCampaignOwnerReminderCommand::class)->daily();
