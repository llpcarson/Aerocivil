;
load "$NCARG_LIB/ncarg/nclscripts/csm/contributed.ncl"
theos = systemfunc("uname")
;

function gen_colormap( )
begin
        ; Set rgb colors

        ; The continental outlines in the map object use this color
        ; as a default.

        return( (/ \
         (/1.00,1.00,1.00/), \  ; white      0
         (/0.00,0.00,0.00/), \  ; black      1
         (/0.00,0.00,1.00/), \  ; blue       2
         (/0.20,0.56,0.80/), \  ; sky blue   3
         (/0.00,1.00,1.00/), \  ; cyan       4
         (/0.50,0.00,1.00/), \  ; blue magenta   5
         (/0.00,1.00,0.00/), \  ; green      6
         (/0.14,0.56,0.14/), \  ; forest green   7
         (/1.00,1.00,0.00/), \  ; yellow      8
         (/1.00,0.50,0.00/), \  ; orange     9
         (/1.00,0.00,1.00/), \ ; magenta   10
         (/1.00,0.00,0.00/), \ ; red       11
         (/0.65,0.16,0.16/), \ ; brown     12
         (/0.86,0.58,0.44/), \ ; tan       13
         (/0.63,0.13,0.94/), \ ; purple    14
         (/0.93,0.51,0.94/), \ ; violet    15
         (/0.00,0.00,0.50/), \ ; navy      16
         (/0.00,0.00,0.80/), \ ; medium blue  17
         (/1.00,0.75,0.80/), \ ; pink        18
         (/0.55,0.24,0.18/), \ ; coral       19
         (/0.60,0.98,0.60/), \ ; pale green     20
         (/1.00,0.76,0.15/), \ ; goldenrod      21
         (/0.66,0.66,0.66/), \ ; light gray    22
         (/0.40,0.40,0.40/) /) ) ; dark gray   23

end
begin

debug = 0 
fname = asciiread("arw1_file.txt",-1,"string")
  grb_file = addfile(fname,"r")
;*  grb_nv_file = addfile(fname_nv,"r")

  names = getfilevarnames(grb_file)  ; Get the variable names in the

if (debug.eq.1) then
  print(names)                       ; GRIB file and print them out.
;
  do i = 0, dimsizes( names ) - 1
    print("Variable Name: " + names(i))
    dims = getfilevardims(grb_file,names(i))
    sizes = filevardimsizes(grb_file,names(i))
    print(dimsizes(sizes) + " Dimensions:")
    if(.not.any(ismissing(dims))) then
      do j = 0, dimsizes(dims) -1
        print( j + ") " + dims(j) + ": " + sizes(j))
      end do  
    end if
    atts = getfilevaratts(grb_file,names(i))
    if(.not.any(ismissing(atts))) then
      do k = 0, dimsizes(atts) -1
        print(atts(k) + ": " +grb_file->$names(i)$@$atts(k)$)
      end do
    end if
    delete(atts)
    delete(dims)
    delete(sizes)
    print("")
  end do
;
  smpl = grb_file->lv_ISBL_103(:)

  do i = 0, 8
   print(i)
   print(smpl(i))
  end do

end if

var_name = "REFD_GDS3_ISBL"
var = grb_file->$var_name$
intm = grb_file->$var_name$@initial_time
fctm = grb_file->$var_name$@forecast_time
lat = grb_file->g3_lat_0(:,:)
lon = grb_file->g3_lon_1(:,:)
latin1 = grb_file->g3_lon_1@Latin1
latin2 = grb_file->g3_lon_1@Latin2
lov = grb_file->g3_lon_1@Lov

printVarSummary(lat)
printVarSummary(lon)
printVarSummary(var)

year = stringtointeger(getSubString(intm,6,9))
mon  = stringtointeger(getSubString(intm,0,1))
day  = stringtointeger(getSubString(intm,3,4))
hour = stringtointeger(getSubString(intm,12,13))
time = (/0.0/)
time@units = "seconds since 1970-01-01 00:00:0.0"
date = ut_inv_calendar(year,mon,day,hour,0,0,time@units, 0)
fcst = (/date + stringtointeger(fctm)*3600/)
fcst@units = "seconds since 1970-01-01 00:00:0.0"
utc_date = ut_calendar(fcst, 0)
year   = floattointeger(utc_date(:,0))    ; Convert to integer for
month  = floattointeger(utc_date(:,1))    ; use in the sprinti function.
day    = floattointeger(utc_date(:,2))
hour   = floattointeger(utc_date(:,3))
minute = floattointeger(utc_date(:,4))
second = utc_date(:,5)
date_str = "Valid " + sprinti("%0.2i/", month) + sprinti("%0.2i/",day) + \
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour)  + \
             "UTC"

lat_pt=275
lon_pt1=240
lon_pt2=340
lon_diff=abs(lon_pt1-lon_pt2)

var_xSec=var(:,lat_pt,lon_pt1:lon_pt2)
print(lat(lat_pt,lon_pt1))
print(lat(lat_pt,lon_pt2))
print(lon(lat_pt,lon_pt1))
print(lon(lat_pt,lon_pt2))

i=0
x_span=14
x_pts=(lon(lat_pt,lon_pt1:lon_pt2))
x_labels=(/decimalPlaces((x_pts(i+(x_span*0))),2,True), decimalPlaces((x_pts(i+(x_span*1))),2,True), decimalPlaces((x_pts(i+(x_span*2))),2,True), decimalPlaces((x_pts(i+(x_span*3))),2,True), decimalPlaces((x_pts(i+(x_span*4))),2,True), decimalPlaces((x_pts(i+(x_span*5))),2,True), decimalPlaces((x_pts(i+(x_span*6))),2,True)/)
;print(x_labels)


wks  = gsn_open_wks("png","ref_xsec_wrfprs")      ; open a ncgm file

gsn_define_colormap(wks,gen_colormap())

res                     = True          ; plot mods desired

res@cnFillOn             = True
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnFillColors         = (/ 0,0,4,3,2,20,6,7,8,21,9,11,19,18,15,14,1 /)
res@cnLevels             = (/ 0.,5.,10.,15.,20.,25.,30.,35.,40.,45.,50.,55.,60.,65.,70.,75. /)
res@cnLineLabelsOn       = False
res@cnLinesOn = False
  
res@tmXBMode = "Explicit"
res@tmXBValues=ispan((i+1),lon_diff,(x_span+1))
res@tmXBLabels=x_labels
res@lbLabelBarOn=True
res@lbLabelOffsetF=0.03
res@lbBoxMinorExtentF=0.2
res@lbLabelFontHeightF=0.019
res@cnMissingValFillColor = "White"

res@tiYAxisString       = "Pressure Level"       ; y-axis title
res@tiXAxisString       = "Longitude"       ; y-axis title
res@tiYAxisOffsetXF = 0.01
res@tiXAxisOffsetYF = 0.18
res@gsnCenterString                 = "Simulated Radar Reflectivity (dbZ)"
res@gsnCenterStringFontColor        = "foreground"
res@gsnCenterStringFontHeightF      = 0.02
res@gsnCenterStringOrthogonalPosF   = 0.005
res@gsnRightString                 = ""+date_str+""
res@gsnRightStringFontHeightF      = 0.015
res@gsnRightStringOrthogonalPosF   = 0.07
res@gsnRightStringParallelPosF      = 1.04
res@gsnLeftString                  = "RAPps "+intm+" "+fctm+" hr fcst"
res@gsnLeftStringFontHeightF       = 0.015
res@gsnLeftStringOrthogonalPosF    = 0.065
res@gsnLeftStringParallelPosF      = -0.065

res@txFont			   = 22

plot = gsn_csm_pres_hgt(wks,var_xSec,res)           ; contour the variable
end
