#Requires AutoHotkey v1.1.35+
;==============================================================
; ColorFormat — Color space conversion helpers for AutoHotkey
;
; GitHub: https://github.com/SevenKeyboard/color-format
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;
; Documentation / References:
;   Color conversion math and formulas
;     https://web.archive.org/web/20111111080001/http://www.easyrgb.com/index.php?X=MATH&H=01
;   Convert Lab color to RGB
;     https://stackoverflow.com/questions/7880264/convert-lab-color-to-rgb
;   Re: Script pressing Left or Right if PixelGetColor approximately correct
;     https://www.autohotkey.com/boards/viewtopic.php?&f=76&t=9406#p55355
;==============================================================

/*
setBatchLines -1

worstAbsError := -1
worstInputRGB := 0
worstTargetL  := 0
worstOutputRGB:= 0
worstResultL  := 0

caseIndex := 0

r := 0
while (r <= 255) {
    g := 0
    while (g <= 255) {
        b := 0
        while (b <= 255) {
            ColorFormat.joinRGB(r, g, b, inputRGB)

            prevResultL := -1
            targetL := 0
            while (targetL <= 100) {

                outputRGB := ColorFormat.adjustBrightnessRGB(inputRGB, targetL)
                ColorFormat.splitRGB(outputRGB, outR, outG, outB)
                ColorFormat.RGBtoCIELab(outR, outG, outB, resultL)

                absError := abs(resultL - targetL)
                if (absError > worstAbsError) {
                    worstAbsError  := absError
                    worstInputRGB  := inputRGB
                    worstTargetL   := targetL
                    worstOutputRGB := outputRGB
                    worstResultL   := resultL
                }

                if (resultL < prevResultL) {
                    msgBox 16, % "Error"
                        , % "Input RGB=" format("{:06X}", inputRGB) "`n"
                        . "Target L*=" targetL "`n"
                        . "Prev L*=" prevResultL "`n"
                        . "Result L*=" resultL "`n"
                        . "Output RGB=" format("{:06X}", outputRGB) "`n"
                        . "`nWorst |L-target|=" round(worstAbsError, 3) "`n"
                        . "Worst @Input=" format("{:06X}", worstInputRGB) "`n"
                        . "Worst target=" worstTargetL "  result=" round(worstResultL, 3) "`n"
                        . "Worst output=" format("{:06X}", worstOutputRGB)
                    ExitApp
                }
                prevResultL := resultL

                if (!mod(caseIndex, 11)) {
                    tooltip, % "Input " format("{:06X}", inputRGB)
                        . "  target=" format("{:07}", round(targetL, 3))
                        . "  L="      Format("{:07}", round(resultL, 3))
                        . "  |e|="    Format("{:07}", round(absError, 3))
                        . "  out "    Format("{:06X}", outputRGB) "`n"
                        . "Worst |e|=" Format("{:07}", round(worstAbsError, 3))
                        . " @ " format("{:06X}", worstInputRGB)
                        . " target=" round(worstTargetL, 3)
                        . " out " format("{:06X}", worstOutputRGB) "`n"
                        . "case=" caseIndex "  elapsed=" round((A_TickCount)/1000, 1) "s"
                }

                targetL += nextStep("targetL")
                caseIndex++
            }
            b += nextStep("b")
        }
        g += nextStep("g")
    }
    r += nextStep("r")
}

tooltip
msgBox 64, % "Done"
    , % "OK`n"
    . "Worst |L-target|=" round(worstAbsError, 3) "`n"
    . "at Input=" format("{:06X}", worstInputRGB) "`n"
    . "target=" round(worstTargetL, 3) "  result=" round(worstResultL, 3) "`n"
    . "output=" format("{:06X}", worstOutputRGB)

nextStep(kind) {
    switch (kind)
    {
        case "r", "g", "b":
            random jitter, 0, 3
            return 16 + jitter
        case "targetL":
            random jitter, 0.0, 1.0
            return 3 + jitter
    }
}
*/

class VersionManager_ColorFormat
{
    static _ := VersionManager_ColorFormat._init()
    _init()    {
        global
        COLORFORMAT_VERSION := "1.0.0"
    }
}
class ColorFormat
{
    splitARGB(ARGB, ByRef A:="", ByRef R:="", ByRef G:="", ByRef B:="")    {
         A:=(ARGB&0xFF000000)>>>24
        ,R:=(ARGB&0xFF0000)>>>16
        ,G:=(ARGB&0xFF00)>>>8
        ,B:=(ARGB&0xFF)
    }
    joinARGB(A, R, G, B, ByRef ARGB:="")    {
        ARGB:=((A&0xFF)<<24)|((R&0xFF)<<16)|((G&0xFF)<<8)|(B&0xFF)
    }
    splitRGB(RGB, ByRef R:="", ByRef G:="", ByRef B:="")    {
         R:=(RGB&0xFF0000)>>>16
        ,G:=(RGB&0xFF00)>>>8
        ,B:=(RGB&0xFF)
    }
    joinRGB(R, G, B, ByRef RGB:="")    {
        RGB:=((R&0xFF)<<16)|((G&0xFF)<<8)|(B&0xFF)
    }
    ;------------------------------------
    ceilRGB(ByRef R:="", ByRef G:="", ByRef B:="")    {
        this._roundingRGB("ceil",R,G,B)
    }
    floorRGB(ByRef R:="", ByRef G:="", ByRef B:="")    {
        this._roundingRGB("floor",R,G,B)
    }
    roundRGB(ByRef R:="", ByRef G:="", ByRef B:="")    {
        this._roundingRGB("round",R,G,B)
    }
    _roundingRGB(funcName, ByRef R, ByRef G, ByRef B)    {
         R:=(%funcName%(R)&0xFF)
        ,G:=(%funcName%(G)&0xFF)
        ,B:=(%funcName%(B)&0xFF)
    }
    ;------------------------------------
    adjustBrightnessRGB(RGB, target_CIEL)    {
        this.splitRGB(RGB,R,G,B)
        this.RGBtoCIELab(R,G,B,CIEL,CIEa,CIEb)
        switch
        {
            default:                                        return RGB
            case (target_CIEL<CIEL):
                lowest_valid_CIEL:=""
                max_CIEL:=CIEL
                min_CIEL:=0
                loop    {
                    curr_testing_CIEL:=min_CIEL+(max_CIEL-min_CIEL)/2
                    this.CIELabtoRGB(curr_testing_CIEL,CIEa,CIEb,curr_R1,curr_G1,curr_B1)
                    if (R<curr_R1 || G<curr_G1 || B<curr_B1) ;  failed
                        min_CIEL:=curr_testing_CIEL
                    else ;  succeed
                        max_CIEL:= lowest_valid_CIEL:= curr_testing_CIEL
                }  until  (format("{1}"
                    ,prior_tested_CIEL==curr_testing_CIEL
                    ,prior_tested_CIEL:=curr_testing_CIEL))
                switch
                {
                    case (lowest_valid_CIEL!=="" && lowest_valid_CIEL<=target_CIEL):
                        this.CIELabtoRGB(target_CIEL,CIEa,CIEb,R,G,B)
                        this.roundRGB(R,G,B)
                        this.joinRGB(R,G,B,RGB)
                        return RGB
                    default:
                        if (lowest_valid_CIEL!=="")
                            this.CIELabtoRGB(lowest_valid_CIEL,CIEa,CIEb,curr_R1,curr_G1,curr_B1)
                        else
                            curr_R1:=R, curr_G1:=G, curr_B1:=B
                        this.RGBtoHSV(curr_R1,curr_G1,curr_B1,curr_H1,,curr_V1)
                        max_V:=curr_V1
                        min_V:=0
                        loop    {
                            curr_testing_V:=min_V+(max_V-min_V)/2
                            this.HSVtoRGB(curr_H1,1,curr_testing_V,curr_R2,curr_G2,curr_B2)
                            this.RGBtoCIELab(curr_R2,curr_G2,curr_B2,curr_CIEL2)
                            if (curr_CIEL2==target_CIEL)
                                break
                            else if (curr_CIEL2<target_CIEL)
                                min_V:=curr_testing_V
                            else if (target_CIEL<curr_CIEL2)
                                max_V:=curr_testing_V
                        }  until  (format("{1}"
                            ,prev_testing_V==curr_testing_V
                            ,prev_testing_V:=curr_testing_V))
                        this.roundRGB(curr_R2,curr_G2,curr_B2)
                        this.joinRGB(curr_R2,curr_G2,curr_B2,RGB)
                        return RGB
                }
            case (CIEL<target_CIEL):
                highest_valid_CIEL:=""
                max_CIEL:=100
                min_CIEL:=CIEL
                loop    {
                    curr_testing_CIEL:=min_CIEL+(max_CIEL-min_CIEL)/2
                    this.CIELabtoRGB(curr_testing_CIEL,CIEa,CIEb,curr_R1,curr_G1,curr_B1)
                    if (curr_R1<R || curr_G1<G || curr_B1<B) ;  failed
                        max_CIEL:=curr_testing_CIEL
                    else ;  succeed
                        min_CIEL:= highest_valid_CIEL:= curr_testing_CIEL
                }  until  (format("{1}"
                    ,prior_tested_CIEL==curr_testing_CIEL
                    ,prior_tested_CIEL:=curr_testing_CIEL))
                switch
                {
                    default:
                        if (highest_valid_CIEL!=="")
                            this.CIELabtoRGB(highest_valid_CIEL,CIEa,CIEb,curr_R1,curr_G1,curr_B1)
                        else
                            curr_R1:=R, curr_G1:=G, curr_B1:=B
                        this.RGBtoHSV(curr_R1,curr_G1,curr_B1,curr_H1,curr_S1)
                        max_S:=curr_S1
                        min_S:=0
                        loop    {
                            curr_testing_S:=min_S+(max_S-min_S)/2
                            this.HSVtoRGB(curr_H1,curr_testing_S,1,curr_R2,curr_G2,curr_B2)
                            this.RGBtoCIELab(curr_R2,curr_G2,curr_B2,curr_CIEL2)
                            if (curr_CIEL2==target_CIEL)
                                break
                            else if (curr_CIEL2<target_CIEL)
                                max_S:=curr_testing_S
                            else if (target_CIEL<curr_CIEL2)
                                min_S:=curr_testing_S
                        }  until  (format("{1}"
                            ,prev_testing_S==curr_testing_S
                            ,prev_testing_S:=curr_testing_S))
                        this.roundRGB(curr_R2,curr_G2,curr_B2)
                        this.joinRGB(curr_R2,curr_G2,curr_B2,RGB)
                        return RGB
                    case (highest_valid_CIEL!=="" && target_CIEL<=highest_valid_CIEL):
                        this.CIELabtoRGB(target_CIEL,CIEa,CIEb,R,G,B)
                        this.roundRGB(R,G,B)
                        this.joinRGB(R,G,B,RGB)
                        return RGB
                }
        }
    }
    ;------------------------------------
    RGBtoCIELab(R, G, B, ByRef CIEL:="", ByRef CIEa:="", ByRef CIEb:="")    {
         this.RGBtoXYZ(R,G,B,X,Y,Z)
        ,this.XYZtoCIELab(X,Y,Z,CIEL,CIEa,CIEb)
    }
    CIELabtoRGB(CIEL, CIEa, CIEb, ByRef R:="", ByRef G:="", ByRef B:="")    {
         this.CIELabtoXYZ(CIEL,CIEa,CIEb,X,Y,Z)
        ,this.XYZtoRGB(X,Y,Z,R,G,B)
    }
    ;------------------------------------
    XYZtoRGB(X, Y, Z, ByRef R:="", ByRef G:="", ByRef B:="")    {
        for _,v in ["X","Y","Z"]
            var_%v%:=%v%/100
         var_R:=var_X*3.240969941904523+var_Y*-1.537383177570094+var_Z*-0.498610760293003
        ,var_G:=var_X*-0.969243636280880+var_Y*1.875967501507721+var_Z*0.041555057407176
        ,var_B:=var_X*0.055630079696994+var_Y*-0.203976958888977+var_Z*1.056971514242879
        for _,v in ["R","G","B"]    {
            var_%v%:=(var_%v%>0.0031308)
                ?1.055*(var_%v%**(1/2.4))-0.055
                :12.92*var_%v%
            ,%v%:=min(255,max(0,var_%v%*255))
        }
    }
    RGBtoXYZ(R, G, B, ByRef X:="", ByRef Y:="", ByRef Z:="")    {
        for _,v in ["R","G","B"]    {
             var_%v%:=(%v%/255)
            ,var_%v%:=(var_%v%>0.04045)
                ?((var_%v%+0.055)/1.055)**2.4
                :var_%v%/12.92
            ,var_%v%*=100
        }
         X:=var_R*0.412390799265959+var_G*0.357584339383878+var_B*0.180480788401834
        ,Y:=var_R*0.212639005871510+var_G*0.715168678767756+var_B*0.072192315360734
        ,Z:=var_R*0.019330818715592+var_G*0.119194779794626+var_B*0.950532152249661
        for _,v in ["X","Y","Z"]
            %v%:=min(this.CIE.XYZ[v],max(0,%v%))
    }
    ;   Which matrix is correct to map XYZ to linear RGB for sRGB?
    ;     https://stackoverflow.com/questions/66360637/which-matrix-is-correct-to-map-xyz-to-linear-rgb-for-srgb
    XYZtoCIELab(X, Y, Z, ByRef CIEL:="", ByRef CIEa:="", ByRef CIEb:="")    {
        for _,v in ["X","Y","Z"]    {
             var_%v%:=%v%/this.CIE.XYZ[v]
            ,var_%v%:=(var_%v%>0.008856)
                ?var_%v%**(1/3)
                :(7.787*var_%v%)+(16/116)
        }
         CIEL:=(116*var_Y)-16
        ,CIEa:=500*(var_X-var_Y)
        ,CIEb:=200*(var_Y-var_Z)
    }
    CIELabtoXYZ(CIEL, CIEa, CIEb, ByRef X:="", ByRef Y:="", ByRef Z:="")    {
         var_Y:=(CIEL+16)/116
        ,var_X:=CIEa/500+var_Y
        ,var_Z:=var_Y-CIEb/200
        for _,v in ["X","Y","Z"]    {
            var_%v%:=(var_%v%**3>0.008856)
                ?var_%v%**3
                :(var_%v%-16/116)/7.787
            %v%:=this.CIE.XYZ[v]*var_%v%
        }
    }
    RGBtoHSL(R, G, B, ByRef H:="", ByRef S:="", ByRef L:="")    {
        for _,v in ["R","G","B"]
            var_%v%:=%v%/255
         var_Min:=min(var_R,var_G,var_B)
        ,var_Max:=max(var_R,var_G,var_B)
        ,del_Max:=var_Max-var_Min
        ,L:=(var_Max+var_Min)/2
        if (del_Max==0)    {
            H:= S:= 0
        }  else  {
            S:=(L<0.5)
                ?del_Max/(var_Max+var_Min)
                :del_Max/(2-var_Max-var_Min)
            for _,v in ["R","G","B"]
                del_%v%:=(((var_Max-var_%v%)/6)+(del_Max/2))/del_Max
            switch
            {
                case (var_R==var_Max):      H:=del_B-del_G
                case (var_G==var_Max):      H:=(1/3)+del_R-del_B
                case (var_B==var_Max):      H:=(2/3)+del_G-del_R
            }
            H+=(H<0?1:1<H?-1:0)
        }
    }
    HSLtoRGB(H, S, L, ByRef R:="", ByRef G:="", ByRef B:="")    {
        if (S==0)    {
            for _,v in ["R","G","B"]
                %v%:=L*255
        }  else  {
             var_2:=(L<0.5)
                ?L*(1+S)
                :(L+S)-(S*L)
            ,var_1:=2*L-var_2
            ,R:=255*this._HuetoRGB(var_1,var_2,H+(1/3))
            ,G:=255*this._HuetoRGB(var_1,var_2,H)
            ,B:=255*this._HuetoRGB(var_1,var_2,H-(1/3))
        }
    }
    _HuetoRGB(v1, v2, vH)    {
        vH+=(vH<0?1:1<vH?-1:0)
        switch
        {
            case (6*vH)<1:          return v1+(v2-v1)*6*vH
            case (2*vH)<1:          return v2
            case (3*vH)<2:          return v1+(v2-v1)*((2/3)-vH)*6
        }
        return v1
    }
    RGBtoHSV(R, G, B, ByRef H:="", ByRef S:="", ByRef V:="")    {
        for _,w in ["R","G","B"]
            var_%w%:=%w%/255
         var_Min:=min(var_R,var_G,var_B)
        ,var_Max:=max(var_R,var_G,var_B)
        ,del_Max:=var_Max-var_Min
        ,V:=var_Max
        if (del_Max==0)    {
            H:= S:= 0
        }  else  {
            S:=del_Max/var_Max
            for _,w in ["R","G","B"]
                del_%w%:=(((var_Max-var_%w%)/6)+(del_Max/2))/del_Max
            switch
            {
                case (var_R==var_Max):      H:=del_B-del_G
                case (var_G==var_Max):      H:=(1/3)+del_R-del_B
                case (var_B==var_Max):      H:=(2/3)+del_G-del_R
            }
            H+=(H<0?1:1<H?-1:0)
        }
    }
    HSVtoRGB(H, S, V, ByRef R:="", ByRef G:="", ByRef B:="")    {
        if (S==0)    {
            for _,w in ["R","G","B"]
                %w%:=V*255
        }  else  {
            var_h:=H*6
            if (var_h==6)
                var_h:=0
             var_i:=floor(var_h)
            ,var_1:=V*(1-S)
            ,var_2:=V*(1-S*(var_h-var_i))
            ,var_3:=V*(1-S*(1-(var_h-var_i)))
            switch (var_i)
            {
                case 0:         var_R:=V, var_G:=var_3, var_B:=var_1
                case 1:         var_R:=var_2, var_G:=V, var_B:=var_1
                case 2:         var_R:=var_1, var_G:=V, var_B:=var_3
                case 3:         var_R:=var_1, var_G:=var_2, var_B:=V
                case 4:         var_R:=var_3, var_G:=var_1, var_B:=V
                default:        var_R:=V, var_G:=var_1, var_B:=var_2
            }
            for _,w in ["R","G","B"]
                %w%:=var_%w%*255
        }
    }
    ;------------------------------------
    Class CIE
    {
        static _:=ColorFormat.CIE._init()
        _init()    {
            this.ColorSpace:="CIE 1964"
            this.Illuminant:="D65"
        }
        ColorSpace    { ;  "CIE 1931", "CIE 1964"
            get  {
                return this._colorSpace
            }
            set  {
                this._colorSpace:=value
            }
        }
        Illuminant    { ;  "A","B","C","D50","D55","D65"...
            get  {
                return this._illuminant
            }
            set  {
                this._illuminant:=value
            }
        }
        Class Yxy
        {
            static _:=ColorFormat.CIE.Yxy._init()
            _init()    {
                this._data:=object()
                this._data["CIE 1931"]:=object()
                cie1931:=this._data["CIE 1931"]
                cie1931["A"]    :=  {x:0.44757, y:0.40745}
                cie1931["B"]    :=  {x:0.34842, y:0.35161}
                cie1931["C"]    :=  {x:0.35161, y:0.31616}
                cie1931["D65"]  :=  {x:0.31271, y:0.32902}
                this._data["CIE 1964"]:=object()
                cie1964:=this._data["CIE 1964"]
                cie1964["A"]    :=  {x:0.45117, y:0.40594}
                cie1964["B"]    :=  {x:0.34980, y:0.35270}
                cie1964["C"]    :=  {x:0.31039, y:0.31905}
                cie1964["D65"]  :=  {x:0.31382, y:0.33100}
            }
            x    {
                get  {
                    return this._data[ColorFormat.CIE.ColorSpace][ColorFormat.CIE.Illuminant].x
                }
            }
            y    {
                get  {
                    return this._data[ColorFormat.CIE.ColorSpace][ColorFormat.CIE.Illuminant].y
                }
            }
        }
        ;   White points of standard illuminants
        ;     https://en.wikipedia.org/wiki/Standard_illuminant#White_points_of_standard_illuminants
        Class XYZ
        {
            static _:=ColorFormat.CIE.XYZ._init()
            _init()    {
                this.Y:=100
            }            
            X    {
                get  {
                    return this.Y/ColorFormat.CIE.Yxy.y*ColorFormat.CIE.Yxy.x
                }
            }
            Y    {
                get  {
                    return this._Y ;  0 to 100
                }
                set  {
                    this._Y:=value
                }
            }
            Z    {
                get  {
                    return this.Y/ColorFormat.CIE.Yxy.y*(1-ColorFormat.CIE.Yxy.x-ColorFormat.CIE.Yxy.y)
                }
            }
        }
        ;   CIE xy chromaticity diagram and the CIE xyY color space
        ;     https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_xy_chromaticity_diagram_and_the_CIE_xyY_color_space
    }
}
/*
XYZ —> RGB
    var_X = X / 100        //X from 0 to  95.047      (Observer = 2°, Illuminant = D65)
    var_Y = Y / 100        //Y from 0 to 100.000
    var_Z = Z / 100        //Z from 0 to 108.883

    var_R = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986
    var_G = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415
    var_B = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570

    if ( var_R > 0.0031308 ) var_R = 1.055 * ( var_R ^ ( 1 / 2.4 ) ) - 0.055
    else                     var_R = 12.92 * var_R
    if ( var_G > 0.0031308 ) var_G = 1.055 * ( var_G ^ ( 1 / 2.4 ) ) - 0.055
    else                     var_G = 12.92 * var_G
    if ( var_B > 0.0031308 ) var_B = 1.055 * ( var_B ^ ( 1 / 2.4 ) ) - 0.055
    else                     var_B = 12.92 * var_B

    R = var_R * 255
    G = var_G * 255
    B = var_B * 255


RGB —> XYZ
    var_R = ( R / 255 )        //R from 0 to 255
    var_G = ( G / 255 )        //G from 0 to 255
    var_B = ( B / 255 )        //B from 0 to 255

    if ( var_R > 0.04045 ) var_R = ( ( var_R + 0.055 ) / 1.055 ) ^ 2.4
    else                   var_R = var_R / 12.92
    if ( var_G > 0.04045 ) var_G = ( ( var_G + 0.055 ) / 1.055 ) ^ 2.4
    else                   var_G = var_G / 12.92
    if ( var_B > 0.04045 ) var_B = ( ( var_B + 0.055 ) / 1.055 ) ^ 2.4
    else                   var_B = var_B / 12.92

    var_R = var_R * 100
    var_G = var_G * 100
    var_B = var_B * 100

    //Observer. = 2°, Illuminant = D65
    X = var_R * 0.4124 + var_G * 0.3576 + var_B * 0.1805
    Y = var_R * 0.2126 + var_G * 0.7152 + var_B * 0.0722
    Z = var_R * 0.0193 + var_G * 0.1192 + var_B * 0.9505


XYZ —> Yxy
    //X from 0 to 95.047       Observer. = 2°, Illuminant = D65
    //Y from 0 to 100.000
    //Z from 0 to 108.883

    Y = Y
    x = X / ( X + Y + Z )
    y = Y / ( X + Y + Z )


Yxy —> XYZ
    //Y from 0 to 100
    //x from 0 to 1
    //y from 0 to 1

    X = x * ( Y / y )
    Y = Y
    Z = ( 1 - x - y ) * ( Y / y )


XYZ —> Hunter-Lab
    (H)L = 10 * sqrt( Y )
    (H)a = 17.5 * ( ( ( 1.02 * X ) - Y ) / sqrt( Y ) )
    (H)b = 7 * ( ( Y - ( 0.847 * Z ) ) / sqrt( Y ) )


Hunter-Lab —> XYZ
    var_Y = (H)L / 10
    var_X = (H)a / 17.5 * (H)L / 10
    var_Z = (H)b / 7 * (H)L / 10

    Y = var_Y ^ 2
    X = ( var_X + Y ) / 1.02
    Z = -( var_Z - Y ) / 0.847


XYZ —> CIE-L*ab
    var_X = X / ref_X          //ref_X =  95.047   Observer= 2°, Illuminant= D65
    var_Y = Y / ref_Y          //ref_Y = 100.000
    var_Z = Z / ref_Z          //ref_Z = 108.883

    if ( var_X > 0.008856 ) var_X = var_X ^ ( 1/3 )
    else                    var_X = ( 7.787 * var_X ) + ( 16 / 116 )
    if ( var_Y > 0.008856 ) var_Y = var_Y ^ ( 1/3 )
    else                    var_Y = ( 7.787 * var_Y ) + ( 16 / 116 )
    if ( var_Z > 0.008856 ) var_Z = var_Z ^ ( 1/3 )
    else                    var_Z = ( 7.787 * var_Z ) + ( 16 / 116 )

    CIE-L* = ( 116 * var_Y ) - 16
    CIE-a* = 500 * ( var_X - var_Y )
    CIE-b* = 200 * ( var_Y - var_Z )


CIE-L*ab —> XYZ
    var_Y = ( CIE-L* + 16 ) / 116
    var_X = CIE-a* / 500 + var_Y
    var_Z = var_Y - CIE-b* / 200

    if ( var_Y^3 > 0.008856 ) var_Y = var_Y^3
    else                      var_Y = ( var_Y - 16 / 116 ) / 7.787
    if ( var_X^3 > 0.008856 ) var_X = var_X^3
    else                      var_X = ( var_X - 16 / 116 ) / 7.787
    if ( var_Z^3 > 0.008856 ) var_Z = var_Z^3
    else                      var_Z = ( var_Z - 16 / 116 ) / 7.787

    X = ref_X * var_X     //ref_X =  95.047     Observer= 2°, Illuminant= D65
    Y = ref_Y * var_Y     //ref_Y = 100.000
    Z = ref_Z * var_Z     //ref_Z = 108.883


CIE-L*ab —> CIE-L*CH°
    var_H = arc_tangent( CIE-b*, CIE-a* )  //Quadrant by signs

    if ( var_H > 0 ) var_H = ( var_H / PI ) * 180
    else             var_H = 360 - ( abs( var_H ) / PI ) * 180

    CIE-L* = CIE-L*
    CIE-C* = sqrt( CIE-a* ^ 2 + CIE-b* ^ 2 )
    CIE-H° = var_H


CIE-L*CH° —>CIE-L*ab
    //CIE-H° from 0 to 360°

    CIE-L* = CIE-L*
    CIE-a* = cos( degree_2_radian( CIE-H° ) ) * CIE-C*
    CIE-b* = sin( degree_2_radian( CIE-H° ) ) * CIE-C*


RGB —> HSL
    var_R = ( R / 255 )                     //RGB from 0 to 255
    var_G = ( G / 255 )
    var_B = ( B / 255 )

    var_Min = min( var_R, var_G, var_B )    //Min. value of RGB
    var_Max = max( var_R, var_G, var_B )    //Max. value of RGB
    del_Max = var_Max - var_Min             //Delta RGB value

    L = ( var_Max + var_Min ) / 2

    if ( del_Max == 0 )                     //This is a gray, no chroma...
    {
        H = 0                                //HSL results from 0 to 1
        S = 0
    }
    else                                    //Chromatic data...
    {
        if ( L < 0.5 ) S = del_Max / ( var_Max + var_Min )
        else           S = del_Max / ( 2 - var_Max - var_Min )

        del_R = ( ( ( var_Max - var_R ) / 6 ) + ( del_Max / 2 ) ) / del_Max
        del_G = ( ( ( var_Max - var_G ) / 6 ) + ( del_Max / 2 ) ) / del_Max
        del_B = ( ( ( var_Max - var_B ) / 6 ) + ( del_Max / 2 ) ) / del_Max

        if      ( var_R == var_Max ) H = del_B - del_G
        else if ( var_G == var_Max ) H = ( 1 / 3 ) + del_R - del_B
        else if ( var_B == var_Max ) H = ( 2 / 3 ) + del_G - del_R

        if ( H < 0 ) H += 1
        if ( H > 1 ) H -= 1
    }


HSL —> RGB
    if ( S == 0 )                       //HSL from 0 to 1
    {
        R = L * 255                      //RGB results from 0 to 255
        G = L * 255
        B = L * 255
    }
    else
    {
        if ( L < 0.5 ) var_2 = L * ( 1 + S )
        else           var_2 = ( L + S ) - ( S * L )

        var_1 = 2 * L - var_2

        R = 255 * Hue_2_RGB( var_1, var_2, H + ( 1 / 3 ) )
        G = 255 * Hue_2_RGB( var_1, var_2, H )
        B = 255 * Hue_2_RGB( var_1, var_2, H - ( 1 / 3 ) )
    }

    Hue_2_RGB( v1, v2, vH )             //Function Hue_2_RGB
    {
        if ( vH < 0 ) vH += 1
        if ( vH > 1 ) vH -= 1
        if ( ( 6 * vH ) < 1 ) return ( v1 + ( v2 - v1 ) * 6 * vH )
        if ( ( 2 * vH ) < 1 ) return ( v2 )
        if ( ( 3 * vH ) < 2 ) return ( v1 + ( v2 - v1 ) * ( ( 2 / 3 ) - vH ) * 6 )
        return ( v1 )
    }


RGB —> HSV
    var_R = ( R / 255 )                     //RGB from 0 to 255
    var_G = ( G / 255 )
    var_B = ( B / 255 )

    var_Min = min( var_R, var_G, var_B )    //Min. value of RGB
    var_Max = max( var_R, var_G, var_B )    //Max. value of RGB
    del_Max = var_Max - var_Min             //Delta RGB value

    V = var_Max

    if ( del_Max == 0 )                     //This is a gray, no chroma...
    {
        H = 0                                //HSV results from 0 to 1
        S = 0
    }
    else                                    //Chromatic data...
    {
        S = del_Max / var_Max

        del_R = ( ( ( var_Max - var_R ) / 6 ) + ( del_Max / 2 ) ) / del_Max
        del_G = ( ( ( var_Max - var_G ) / 6 ) + ( del_Max / 2 ) ) / del_Max
        del_B = ( ( ( var_Max - var_B ) / 6 ) + ( del_Max / 2 ) ) / del_Max

        if      ( var_R == var_Max ) H = del_B - del_G
        else if ( var_G == var_Max ) H = ( 1 / 3 ) + del_R - del_B
        else if ( var_B == var_Max ) H = ( 2 / 3 ) + del_G - del_R

        if ( H < 0 ) H += 1
        if ( H > 1 ) H -= 1
    }


HSV —> RGB
    if ( S == 0 )                       //HSV from 0 to 1
    {
        R = V * 255
        G = V * 255
        B = V * 255
    }
    else
    {
        var_h = H * 6
        if ( var_h == 6 ) var_h = 0      //H must be < 1
        var_i = int( var_h )             //Or ... var_i = floor( var_h )
        var_1 = V * ( 1 - S )
        var_2 = V * ( 1 - S * ( var_h - var_i ) )
        var_3 = V * ( 1 - S * ( 1 - ( var_h - var_i ) ) )

        if      ( var_i == 0 ) { var_r = V     ; var_g = var_3 ; var_b = var_1 }
        else if ( var_i == 1 ) { var_r = var_2 ; var_g = V     ; var_b = var_1 }
        else if ( var_i == 2 ) { var_r = var_1 ; var_g = V     ; var_b = var_3 }
        else if ( var_i == 3 ) { var_r = var_1 ; var_g = var_2 ; var_b = V     }
        else if ( var_i == 4 ) { var_r = var_3 ; var_g = var_1 ; var_b = V     }
        else                   { var_r = V     ; var_g = var_1 ; var_b = var_2 }

        R = var_r * 255                  //RGB results from 0 to 255
        G = var_g * 255
        B = var_b * 255
    }


RGB —> CMY
    //RGB values from 0 to 255
    //CMY results from 0 to 1

    C = 1 - ( R / 255 )
    M = 1 - ( G / 255 )
    Y = 1 - ( B / 255 )


CMY —> RGB
    //CMY values from 0 to 1
    //RGB results from 0 to 255

    R = ( 1 - C ) * 255
    G = ( 1 - M ) * 255
    B = ( 1 - Y ) * 255


CMY —> CMYK
    //CMYK and CMY values from 0 to 1

    var_K = 1

    if ( C < var_K )   var_K = C
    if ( M < var_K )   var_K = M
    if ( Y < var_K )   var_K = Y
    if ( var_K == 1 ) { //Black
        C = 0
        M = 0
        Y = 0
    }
    else {
        C = ( C - var_K ) / ( 1 - var_K )
        M = ( M - var_K ) / ( 1 - var_K )
        Y = ( Y - var_K ) / ( 1 - var_K )
    }
    K = var_K


CMYK —> CMY
    //CMYK and CMY values from 0 to 1

    C = ( C * ( 1 - K ) + K )
    M = ( M * ( 1 - K ) + K )
    Y = ( Y * ( 1 - K ) + K )
*/