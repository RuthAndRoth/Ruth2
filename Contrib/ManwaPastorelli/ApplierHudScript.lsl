/*
BSD 3-Clause License
Copyright (c) 2019, Sara Payne (Manwa Pastorelli in virtual worlds)
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//LinkNumbers
list linkSet0;// = [linkBtnEyes0, linkBtnHead0, linkBtnUpper0, linkBtnLower0];
list linkSet1;// = [linkBtnEyes1, linkBtnHead1, linkBtnUpper1, linkBtnLower1];
list linkSet2;// = [linkBtnEyes2, linkBtnHead2, linkBtnUpper2, linkBtnLower2];
list linkSet3;// = [linkBtnEyes3, linkBtnHead3, linkBtnUpper3, linkBtnLower3];
list linkSet4;// = [linkBtnEyes4, linkBtnHead4, linkBtnUpper4, linkBtnLower4];
list linkSet5;// = [linkBtnEyes5, linkBtnHead5, linkBtnUpper5, linkBtnLower5];
list linkSet6;// = [linkBtnEyes6, linkBtnHead6, linkBtnUpper6, linkBtnLower6];
list linkSet7;// = [linkBtnEyes7, linkBtnHead7, linkBtnUpper7, linkBtnLower7];
list linkSet8;// = [linkBtnEyes8, linkBtnHead8, linkBtnUpper8, linkBtnLower8];

integer maskCutOff = 0;

//Debug
integer debug = FALSE; 

//CommunicationChannels
integer r2chan;
integer menuChannel;
integer menuChannelListen;
integer appID = 20181024; //changes between ruth/roth etc

//userTouches
integer touchedLink; //touched link number
vector touchedUV;  //position vector of the touched UV

integer keyapp2chan()
{
    return 0x80000000 | ((integer)("0x"+(string)llGetOwner()) ^ appID);
}

SetupLinkNos()
{
    integer btnApplyAll0; integer btnApplyAll1; integer btnApplyAll2; integer btnApplyAll3; integer btnApplyAll4; integer btnApplyAll5; integer btnApplyAll6; integer btnApplyAll7; integer btnApplyAll8; 
    
    integer btnEyes0; integer btnEyes1; integer btnEyes2; integer btnEyes3; integer btnEyes4; integer btnEyes5; integer btnEyes6; integer btnEyes7; integer btnEyes8; 
 
    integer btnHead0; integer btnHead1; integer btnHead2; integer btnHead3; integer btnHead4; integer btnHead5; integer btnHead6; integer btnHead7; integer btnHead8;
 
    integer btnUpper0; integer btnUpper1; integer btnUpper2; integer btnUpper3; integer btnUpper4; integer btnUpper5; integer btnUpper6; integer btnUpper7; integer btnUpper8;

    integer btnLower0; integer btnLower1; integer btnLower2; integer btnLower3; integer btnLower4; integer btnLower5; integer btnLower6; integer btnLower7; integer btnLower8;

    integer linkIndex;
    for (linkIndex = 2; linkIndex <= llGetNumberOfPrims(); linkIndex++)
    {   //loop through all links assigning link numbers to apropriate vairable names
        list linkParams = llGetLinkPrimitiveParams(linkIndex, [PRIM_NAME, PRIM_DESC]);
        string linkName = llList2String(linkParams,0);
        if (linkName == "BtnApplyAll0") btnApplyAll0 = linkIndex;
        else if (linkName == "BtnApplyAll1") btnApplyAll1 = linkIndex;
        else if (linkName == "BtnApplyAll2") btnApplyAll2 = linkIndex; 
        else if (linkName == "BtnApplyAll3") btnApplyAll3 = linkIndex;
        else if (linkName == "BtnApplyAll4") btnApplyAll4 = linkIndex;
        else if (linkName == "BtnApplyAll5") btnApplyAll5 = linkIndex;
        else if (linkName == "BtnApplyAll6") btnApplyAll6 = linkIndex;
        else if (linkName == "BtnApplyAll7") btnApplyAll7 = linkIndex;
        else if (linkName == "BtnApplyAll8") btnApplyAll8 = linkIndex;
        else if (linkName == "BtnEyes0") btnEyes0 = linkIndex;
        else if (linkName == "BtnEyes1") btnEyes1 = linkIndex;
        else if (linkName == "BtnEyes2") btnEyes2 = linkIndex;
        else if (linkName == "BtnEyes3") btnEyes3 = linkIndex;
        else if (linkName == "BtnEyes4") btnEyes4 = linkIndex;
        else if (linkName == "BtnEyes5") btnEyes5 = linkIndex;
        else if (linkName == "BtnEyes6") btnEyes6 = linkIndex;
        else if (linkName == "BtnEyes7") btnEyes7 = linkIndex;
        else if (linkName == "BtnEyes8") btnEyes8 = linkIndex;
        else if (linkName == "BtnHead0") btnHead0 = linkIndex;
        else if (linkName == "BtnHead1") btnHead1 = linkIndex;
        else if (linkName == "BtnHead2") btnHead2 = linkIndex;
        else if (linkName == "BtnHead3") btnHead3 = linkIndex;
        else if (linkName == "BtnHead4") btnHead4 = linkIndex;
        else if (linkName == "BtnHead5") btnHead5 = linkIndex;
        else if (linkName == "BtnHead6") btnHead6 = linkIndex;
        else if (linkName == "BtnHead7") btnHead7 = linkIndex;
        else if (linkName == "BtnHead8") btnHead8 = linkIndex;
        else if (linkName == "BtnUpper0") btnUpper0 = linkIndex;
        else if (linkName == "BtnUpper1") btnUpper1 = linkIndex;
        else if (linkName == "BtnUpper2") btnUpper2 = linkIndex;
        else if (linkName == "BtnUpper3") btnUpper3 = linkIndex;
        else if (linkName == "BtnUpper4") btnUpper4 = linkIndex;
        else if (linkName == "BtnUpper5") btnUpper5 = linkIndex;
        else if (linkName == "BtnUpper6") btnUpper6 = linkIndex;
        else if (linkName == "BtnUpper7") btnUpper7 = linkIndex;
        else if (linkName == "BtnUpper8") btnUpper8 = linkIndex;
        else if (linkName == "BtnLower0") btnLower0 = linkIndex;
        else if (linkName == "BtnLower1") btnLower1 = linkIndex;
        else if (linkName == "BtnLower2") btnLower2 = linkIndex;
        else if (linkName == "BtnLower3") btnLower3 = linkIndex;
        else if (linkName == "BtnLower4") btnLower4 = linkIndex;
        else if (linkName == "BtnLower5") btnLower5 = linkIndex;
        else if (linkName == "BtnLower6") btnLower6 = linkIndex;
        else if (linkName == "BtnLower7") btnLower7 = linkIndex;
        else if (linkName == "BtnLower8") btnLower8 = linkIndex;
    }
    linkSet0 = [btnEyes0, btnHead0, btnUpper0, btnLower0];
    linkSet1 = [btnEyes1, btnHead1, btnUpper1, btnLower1];
    linkSet2 = [btnEyes2, btnHead2, btnUpper2, btnLower2];
    linkSet3 = [btnEyes3, btnHead3, btnUpper3, btnLower3];
    linkSet4 = [btnEyes4, btnHead4, btnUpper4, btnLower4];
    linkSet5 = [btnEyes5, btnHead5, btnUpper5, btnLower5];
    linkSet6 = [btnEyes6, btnHead6, btnUpper6, btnLower6];
    linkSet7 = [btnEyes7, btnHead7, btnUpper7, btnLower7];
    linkSet8 = [btnEyes8, btnHead8, btnUpper8, btnLower8];
}

SendToBody(string messageToBody)
{
    llRegionSay(r2chan, messageToBody);
    if (debug) llOwnerSay("Debug:SentToBody:Message: " + messageToBody);
}

ApplyAllTextures(integer set)
{   //loop through the list of items to send and send the details. 
    if(debug) llOwnerSay("Debug:ApplyAllTextures:SetNumber: " + (string)set);
    list linksToProcess;
    if (set == 0) linksToProcess = linkSet0;
    else if (set == 1) linksToProcess = linkSet1;
    else if (set == 2) linksToProcess = linkSet2;
    else if (set == 3) linksToProcess = linkSet3;
    else if (set == 4) linksToProcess = linkSet4;
    else if (set == 5) linksToProcess = linkSet5;
    else if (set == 6) linksToProcess = linkSet6;
    else if (set == 7) linksToProcess = linkSet7;
    else if (set == 8) linksToProcess = linkSet8;
    integer index;
    for (index = 0; index < llGetListLength(linksToProcess); index++)
    {   //loop through all links in the list
        ApplySpecificTexture(llList2Integer(linksToProcess, index));
    }
}

ApplySpecificTexture(integer linkNumber)
{
    list linkParamList = llGetLinkPrimitiveParams(linkNumber,[PRIM_NAME, PRIM_DESC, PRIM_TEXTURE, 0, PRIM_NORMAL, 0, PRIM_SPECULAR, 0, PRIM_COLOR, 0, PRIM_GLOW, 0]);
    string primName = llList2String(linkParamList,0);
    string primDesc = llList2String(linkParamList,1);
    string primDiffuse;
    if (primName == "BtnEyes0") primDiffuse = "52cc6bb6-2ee5-e632-d3ad-50197b1dcb8a"; //IMG_USE_BAKED_EYES
    else if (primName == "BtnHead0") primDiffuse = "5a9f4a74-30f2-821c-b88d-70499d3e7183"; //IMG_USE_BAKED_HEAD
    else if (primName == "BtnUpper0") primDiffuse = "ae2de45c-d252-50b8-5c6e-19f39ce79317"; //IMG_USE_BAKED_UPPER
    else if (primName == "BtnLower0") primDiffuse = "24daea5f-0539-cfcf-047f-fbc40b2786ba"; //IMG_USE_BAKED_LOWER
    else primDiffuse = llList2String(linkParamList,2);
    string primNormal = llList2String(linkParamList, 6);
    string primSpecular = llList2String(linkParamList, 10);
    string primSpecColor = llList2String(linkParamList, 14);
    string primSpecGloss = llList2String(linkParamList, 15);
    string primSpecEnvir = llList2String(linkParamList, 16);
    string primColor = llList2String(linkParamList, 17);
    string primGlow = llList2String(linkParamList, 18);
    string messageToBody = "TEXTURE" + "," + 
                            primDesc + "," + 
                            primDiffuse + "," + 
                            primNormal + "," + 
                            primSpecular + "," +
                            primSpecColor + "," +
                            primSpecGloss + "," +
                            primSpecEnvir + "," + 
                            primColor + "," +
                            primGlow;
    SendToBody(messageToBody);
}

SetAlphaMode(integer primAlphaMode)
{
    string messageToBody = "ALPHAMODE" + "," + (string)primAlphaMode + "," + (string)maskCutOff;
    SendToBody(messageToBody);
}

TextBox(string reason)
{
    //add code here
}

default
{
    state_entry()
    {
        SetupLinkNos();
        r2chan = keyapp2chan();
    }

    touch_start( integer num_detected )
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            touchedLink = llDetectedLinkNumber(0); //touched link number
            if (touchedLink != LINK_ROOT)
            {
                string btnName = llGetLinkName(touchedLink);
                if (debug) llOwnerSay("Debug:TouchStart:BtnName: " + btnName);
                integer length = llStringLength(btnName);
                string btnType = llGetSubString(btnName, 0, length-2);
                if (debug) llOwnerSay("Debug:TouchStart:BtnType: " + btnType);
                if (btnType == "BtnApplyAll")
                {
                    if (debug) llOwnerSay("Debug:TouchStart:ApplyAll Found");
                    string tail = llGetSubString(btnName, length-1, length-1);
                    if (debug) llOwnerSay("Debug:TouchStart:Tail: " + tail);
                    ApplyAllTextures((integer)tail);
                }
                else
                {
                    if (debug) llOwnerSay("Debug:TouchStart:ApplySingle Found");
                    ApplySpecificTexture(touchedLink);
                }
                
            }
            
        }
    }
}