$moves = @{
    "lib/view/fontend/sign_in.dart" = "lib/presentation/views/auth/sign_in_view.dart"
    "lib/view/fontend/sign_up.dart" = "lib/presentation/views/auth/sign_up_view.dart"
    "lib/view/fontend/forgot_password_view.dart" = "lib/presentation/views/auth/forgot_password_view.dart"
    "lib/view/fontend/Home_view.dart" = "lib/presentation/views/home/home_view.dart"
    "lib/view/fontend/bmi_view.dart" = "lib/presentation/views/bmi/bmi_view.dart"
    "lib/view/fontend/bmi_records_view.dart" = "lib/presentation/views/bmi/bmi_records_view.dart"
    "lib/view/fontend/calo_tracking_view.dart" = "lib/presentation/views/nutrition/calo_tracking_view.dart"
    "lib/view/fontend/schedule_view.dart" = "lib/presentation/views/workout/schedule_view.dart"
    "lib/view/fontend/workout_session_view.dart" = "lib/presentation/views/workout/workout_session_view.dart"
    "lib/view/fontend/settings_view.dart" = "lib/presentation/views/settings/settings_view.dart"
    "lib/view/fontend/ui.dart" = "lib/presentation/widgets/ui.dart"
    "lib/view/widgets/Ui.dart" = "lib/presentation/widgets/ui_background.dart"
}

Write-Host "Copying files..."
foreach ($oldPath in $moves.Keys) {
    $newPath = $moves[$oldPath]
    $fullOldPath = Join-Path "e:\anh_chinh\app_mobie\flutter_application_1" $oldPath
    $fullNewPath = Join-Path "e:\anh_chinh\app_mobie\flutter_application_1" $newPath
    if (Test-Path $fullOldPath) {
        $parent = Split-Path $fullNewPath
        if (!(Test-Path $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }
        Copy-Item -Path $fullOldPath -Destination $fullNewPath -Force
        Write-Host "Copied $oldPath to $newPath"
    }
}

Write-Host "Updating imports..."
$dartFiles = Get-ChildItem -Path "e:\anh_chinh\app_mobie\flutter_application_1\lib" -Filter "*.dart" -Recurse | Where-Object { !($_.Attributes -match "Directory") }

$replacements = @(
    @("bmi_record.dart", "package:flutter_application_1/data/models/bmi_record.dart"),
    @("calisthenics_exercise.dart", "package:flutter_application_1/data/models/calisthenics_exercise.dart"),
    @("food_item.dart", "package:flutter_application_1/data/models/food_item.dart"),
    @("meal_entry.dart", "package:flutter_application_1/data/models/meal_entry.dart"),
    @("planned_exercise.dart", "package:flutter_application_1/data/models/planned_exercise.dart"),
    @("vitamin_goal.dart", "package:flutter_application_1/data/models/vitamin_goal.dart"),
    @("workout_exercise.dart", "package:flutter_application_1/data/models/workout_exercise.dart"),
    @("bmi_service.dart", "package:flutter_application_1/data/repositories/bmi_repository.dart"),
    @("data_seeder_service.dart", "package:flutter_application_1/data/repositories/data_seeder_repository.dart"),
    @("language_service.dart", "package:flutter_application_1/data/repositories/language_repository.dart"),
    @("nutrition_service.dart", "package:flutter_application_1/data/repositories/nutrition_repository.dart"),
    @("workout_service.dart", "package:flutter_application_1/data/repositories/workout_repository.dart"),
    @("caculate_BMI.dart", "package:flutter_application_1/domain/calculate_bmi.dart"),
    @("sign_in.dart", "package:flutter_application_1/presentation/views/auth/sign_in_view.dart"),
    @("sign_up.dart", "package:flutter_application_1/presentation/views/auth/sign_up_view.dart"),
    @("forgot_password_view.dart", "package:flutter_application_1/presentation/views/auth/forgot_password_view.dart"),
    @("Home_view.dart", "package:flutter_application_1/presentation/views/home/home_view.dart"),
    @("bmi_view.dart", "package:flutter_application_1/presentation/views/bmi/bmi_view.dart"),
    @("bmi_records_view.dart", "package:flutter_application_1/presentation/views/bmi/bmi_records_view.dart"),
    @("calo_tracking_view.dart", "package:flutter_application_1/presentation/views/nutrition/calo_tracking_view.dart"),
    @("schedule_view.dart", "package:flutter_application_1/presentation/views/workout/schedule_view.dart"),
    @("workout_session_view.dart", "package:flutter_application_1/presentation/views/workout/workout_session_view.dart"),
    @("settings_view.dart", "package:flutter_application_1/presentation/views/settings/settings_view.dart"),
    @("ui\.dart", "package:flutter_application_1/presentation/widgets/ui.dart"),
    @("Ui\.dart", "package:flutter_application_1/presentation/widgets/ui_background.dart")
)

foreach ($file in $dartFiles) {
    # Skip the old view/fontend files to avoid access denied errors
    if ($file.FullName -match "\\view\\fontend\\" -or $file.FullName -match "\\view\\widgets\\") {
        continue
    }

    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    foreach ($pair in $replacements) {
        $key = $pair[0]
        $val = $pair[1]
        $pattern = "(?-i)^import\s+['""](?!package:|dart:)[^'""]*$key['""]\s*;"
        $replacement = "import '$val';"
        $content = [regex]::Replace($content, "(?m)" + $pattern, $replacement)
    }

    if ($content -cne $originalContent) {
        try {
            [IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
            Write-Host "Updated imports in $($file.Name)"
        } catch {
            Write-Host "Failed to update $($file.Name): $($_.Exception.Message)"
        }
    }
}
Write-Host "Done!"
