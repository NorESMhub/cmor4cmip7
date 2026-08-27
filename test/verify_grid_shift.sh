#!/usr/bin/env bash

cd /scratch/yanchun/cmorout/UKESM1-0-LL/piControl
ver1=v20260709  # version before c-grid shfiting
ver2=v20260814  # version after c-grid shfiting

# ncrng $var_nm $fl_nm : What is range of variable?
function ncrng { ncap2 -O -C -v -s "foo_min=${1}.min();foo_max=${1}.max();print(foo_min,\"%f\");print(\" to \");print(foo_max,\"%f\")" ${2} /tmp/foo.nc ; command rm -f /tmp/foo.nc; }

# color code
bold=$(tput bold)
red=$(tput setaf 4)
reset=$(tput sgr0)

# 1. test fx p areacello, OK
echo "${bold}areacello (p-point) ${reset}"
ncks -O -F -d j,1,384 ${ver1}/areacello_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc areacello.nc
ncdiff -O areacello.nc ${ver2}/areacello_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc darea.nc
echo "ncdiff range:"
ncrng areacello darea.nc    # 0
echo ""

# 2. test fx p dxto, OK
echo "${bold}dxto (p-point)${reset}"
ncks -O -F -d j,1,384 ${ver1}/dxto_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dxto.nc
ncdiff -O dxto.nc ${ver2}/dxto_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc ddxto.nc
echo "ncdiff range:"
ncrng dxto ddxto.nc # 0
echo ""

# 3. test fx p dyto, OK
echo "${bold}dyto (p-point)${reset}"
ncks -O -F -d j,1,384 ${ver1}/dyto_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyto.nc
ncdiff -O dyto.nc ${ver2}/dyto_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc ddyto.nc
echo "ncdiff range:"
ncrng dyto ddyto.nc #0
echo ""

# 4. test fx v dxvo, OK
echo "${bold}dxvo (v-point)${reset}"
ncks -O -F -d j,2,385 ${ver1}/dxvo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dxvo.nc
ncdiff -O dxvo.nc ${ver2}/dxvo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc ddxvo.nc
echo "ncdiff range:"
ncrng dxvo ddxvo.nc     # 0
echo ""

# 5. test fx v dyvo, OK
echo "${bold}dyvo (v-point)${reset}"
ncks -O -F -d j,2,385 ${ver1}/dyvo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyvo.nc
ncdiff -O dyvo.nc ${ver2}/dyvo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc ddyvo.nc
echo "ncdiff range:"
ncrng dyvo ddyvo.nc     # 0
echo ""

# 6. test dyuo, OK
echo "${bold}dyuo (u-point)${reset}"
ncks -O -F -d i,2,360 -d j,1,384 ${ver1}/dyuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyuo.nc
ncks -O -F -d i,1,359 -d j,1,384 ${ver2}/dyuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyuo2.nc
ncdiff -O dyuo.nc dyuo2.nc ddyuo.nc
echo "ncdiff range:"
ncrng dyuo ddyuo.nc     # 0
ncks -O -F -d i,1 -d j,1,384 ${ver1}/dyuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyuo.nc
ncks -O -F -d i,360 -d j,1,384 ${ver2}/dyuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dyuo2.nc
ncdiff -O dyuo.nc dyuo2.nc ddyuo.nc
echo "ncdiff range:"
ncrng dyuo ddyuo.nc     # 0
echo ""

# 7. test dxuo, OK
echo "${bold}dxuo (u-point)${reset}"
ncks -O -F -d i,2,360 -d j,1,384 ${ver1}/dxuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dxuo.nc
ncks -O -F -d i,1,359 -d j,1,384 ${ver2}/dxuo_ti-u-hxy-u_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dxuo2.nc
ncdiff -O dxuo.nc dxuo2.nc ddxuo.nc
echo "ncdiff range:"
ncrng dxuo ddxuo.nc     # 0
echo ""

# 8. test fx 3D p thkcello, OK
echo "${bold}thkcello (p-point, 3D)${reset}"
ncks -O -F -d j,1,384 ${ver1}/thkcello_ti-ol-hxy-sea_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc thkcello.nc
ncdiff -O thkcello.nc ${ver2}/thkcello_ti-ol-hxy-sea_fx_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1.nc dthkcello.nc
echo "ncdiff range:"
ncrng thkcello dthkcello.nc    # 0
echo ""

# 9. test tos at p-points, OK!
echo "${bold}tos (p-point, 2D)${reset}"
ncks -O -F -d j,1,384 ${ver1}/tos_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc tos.nc
ncdiff -O tos.nc ${ver2}/tos_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc dtos.nc
echo "ncdiff range:"
ncrng tos dtos.nc   # 0
echo ""

# 10. test hfx at p-point, OK
echo "${bold}hfx (u-point, 2D)${reset}"
ncks -O -F -d i,2,360 -d j,1,384 ${ver1}/hfx_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc hfx.nc
ncks -O -F -d i,1,359 -d j,1,384 ${ver2}/hfx_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc hfx2.nc
ncdiff -O hfx.nc hfx2.nc dhfx.nc
echo "ncdiff range:"
ncrng hfx dhfx.nc     # 
echo ""

# test hfy at v-point, OK
echo "${bold}hfy (v-point, 2D)${reset}"
ncks -O -F -d j,2,385 ${ver1}/hfy_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc hfy.nc
ncdiff -O hfy.nc ${ver2}/hfy_tavg-u-hxy-sea_mon_glb_g99_UKESM1-0-LL_piControl_r1i1p1f1_134101-134112.nc dhfy.nc
echo "ncdiff range:"
ncrng hfy dhfy.nc     # 0
echo ""
