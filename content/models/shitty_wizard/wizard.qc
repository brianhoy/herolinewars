// Created by Crowbar 0.29.0.0

$ModelName "creeps/lane_creeps/wizard/wizard.mdl"

$BodyGroup "wizard"
{
	studio "wizard_reference.smd"
}


$SurfaceProp "default"

$Contents "solid"

$MaxEyeDeflection 90

$CDMaterials "models\creeps\lane_creeps\wizard\"

$Attachment "attach_portrait" "base" 0 75 125 rotate 90 90 0
$Attachment "attach_hitloc" "base" 0 62.5 0 rotate 0 0 0

$CBox 0 0 0 0 0 0

$BBox -36.849 -25.902 -0.688 26.094 25.898 116.018


$Sequence "idle" {
	"wizard_anims\idle.smd"
	activity "ACT_DOTA_IDLE" 1
	fadein 0.2
	fadeout 0.2
	fps 60
}

$Sequence "run" {
	"wizard_anims\run.smd"
	activity "ACT_DOTA_RUN" 1
	fadein 0.2
	fadeout 0.2
	fps 120
	loop
}

$Sequence "attack" {
	"wizard_anims\attack.smd"
	activity "ACT_DOTA_ATTACK1" 1
	fadein 0.2
	fadeout 0.2
	fps 60
}

$Sequence "die" {
	"wizard_anims\die.smd"
	activity "ACT_DOTA_DIE" 1
	fadein 0.2
	fadeout 0.2
	fps 60
}
