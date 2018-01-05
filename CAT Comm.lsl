list GL_Terminals;
list GL_Term_Names;


key GK_TargetTerm = NULL_KEY;
integer GI_TargetChan;


integer GI_Speaker = 2;


list GL_Sounds = [
    "6d02ae44-cc3b-2ff3-957d-dace9d982abf",
    "0cca0a78-b49d-0f01-a20e-b844bf7b8902",
    "2bf54c2e-f35c-e6b9-d77b-bf083df7b18b",
    "97241397-3f89-49fe-b130-3437de893c83",
    "4984fb18-8b44-2eab-6cd7-826c07e1ec5b"
];


integer GI_Listen_A;
integer GI_Listen_B;
integer GI_Open;
key GK_User = NULL_KEY;

integer GI_Page;



procTerminal( key id, string name ) {
    integer index = llListFindList( GL_Terminals, [id] );
    if( index == -1 ) {
        index = llGetListLength( GL_Terminals );
        GL_Terminals += id;
        GL_Term_Names += [index, name];
    } else {
        integer point = llListFindList( GL_Term_Names, [index] );
        GL_Term_Names = llListReplaceList( GL_Term_Names, [name], point+1, point+1 );
    }
}



key getRootId( key id ) {
    return llList2Key( llGetObjectDetails( id, [OBJECT_ROOT] ), 0);
}

string getRootName( key id ) {
    key root = getRootId( id );
    if( root != NULL_KEY ) {
        return llList2String( llGetObjectDetails( root, [OBJECT_NAME] ), 0 );
    }
    return "";
}

string getRootDesc( key id ) {
    key root = getRootId( id );
    if( root != NULL_KEY ) {
        return llList2String( llGetObjectDetails( root, [OBJECT_DESC] ), 0 );
    }
    return "";
}


doSay( string msg ) {
    llMessageLinked( GI_Speaker, 400, msg, "CH" );
    llSleep( 0.2 );
}

doBroadcast( string msg, key id ) {
    llMessageLinked( GI_Speaker, 500, msg,  id );
    llSleep( 0.2 );
}


openListen() {
    if( GK_User != NULL_KEY ) {
        llTriggerSound( "07674212-ac01-c2b5-80cc-01554da46433", 1 );
        //llLoopSound( "67c8c1bd-3c15-e2ac-b637-c37ce4f89e76", 0.25 );
        llSetText( "", <1,1,1>, 1.0 );
        llListenRemove( GI_Listen_A );
        llListenRemove( GI_Listen_B );
        GI_Listen_A = llListen( 9, "", GK_User, "" );
        GI_Listen_B = llListen( 9999, "", GK_User, "" );
        GI_Open = TRUE;
    }
}


closeListen() {
    llStopSound();
    llTriggerSound( "2124bce0-0d39-7aeb-8b95-6f15e9a987e2", 1 );
    llSetLinkPrimitiveParamsFast( GI_Speaker, [PRIM_NAME, "The "+ llGetObjectDesc() +" Intercomm" ] );
    doSay( "/me goes idle." );
    GI_Open = FALSE;
    GK_User = NULL_KEY;
    GK_TargetTerm = NULL_KEY;
    GI_Page = 0;
    llListenRemove( GI_Listen_A );
    llListenRemove( GI_Listen_B );
    llSetTimerEvent( 0 );
}




openDialog() {
    llSetTimerEvent( 30 );
    integer noe = llGetListLength( GL_Terminals );
    integer pages = (integer)llCeil(noe / 9.0);
    
    list buttons = [];
    string text = "";
    if( GK_TargetTerm != NULL_KEY ) {
        text = "Speak on Channel 9 to send message\n";
    } else {
        text = "Select Target Intercom\n";
    }
    if( pages >= 2 ) {
        buttons += ["<<", "Close", ">>"];
    } else {
        buttons += ["-", "Close", "-"];
    }
    
    integer i;
    for( i=0; i<9; i++ ) {
        integer mark = (GI_Page*9) + i;
        if( mark < noe ) {
            text += "#"+ llList2String( GL_Term_Names, (mark*2)) +" "+ llList2String( GL_Term_Names, (mark*2)+1) +"\n";
            buttons += "#"+ llList2String( GL_Term_Names, (mark*2) );
        } else {
            buttons += "-";
        }
    }
    llDialog( GK_User, text, buttons, 9999 );
}

procCmd( string msg ) {
    if( msg == "Close" ) {
        closeListen();
        return;
    } else if( msg == "<<" ) {
        GI_Page -= 1;
        if( GI_Page < 0 ) {
            GI_Page = (integer)llCeil(llGetListLength( GL_Terminals ) / 9.0) - GI_Page;
        }
    } else if( msg == ">>" ) {
        GI_Page = (GI_Page+1) % (integer)llCeil(llGetListLength( GL_Terminals ) / 9.0);
    } else if( llGetSubString( msg, 0, 0 ) == "#" ) {
        integer index = (integer)llGetSubString( msg, 1, -1 );
        if( index < llGetListLength( GL_Terminals ) ) {
            GK_TargetTerm = llList2Key( GL_Terminals, index );
            GI_TargetChan = 3333;
            integer mark = llListFindList( GL_Term_Names, [index] )+1;
            if( mark != 0 ) {
                llSetLinkPrimitiveParamsFast( GI_Speaker, [PRIM_NAME, "The "+ llGetObjectDesc() +" Intercomm"] );
                doSay( "/me open a connection to the "+ llList2String( GL_Term_Names, mark ) +" Intercomm" );
            }
        }
    }
    openDialog();
}






default {
    state_entry() {
        integer side = 0;
        llSetTextureAnim( ANIM_ON | LOOP, side,4,4,0,0,12 );
        llListen( 2221, llGetObjectName(), "", "comm|ping" );
        llListen( 2222, llGetObjectName(), "", "comm|pong" );
        llListen( 3333, "", "", "" );
    }
    
    
    
    touch_end( integer num ) {
        if( llVecDist( llGetPos(), llDetectedPos(0) ) <= 10 ) {
            if( GK_User == NULL_KEY ) {
                llTriggerSound( "8f1c47c5-81cb-f3b8-a3e7-6be9006ed7ed", 1 );
                string name = llDetectedName(0);
                llSetLinkPrimitiveParamsFast( GI_Speaker, [PRIM_NAME, name ] );
                doSay( "/me has activated the "+ llGetObjectDesc() +" Intercomm." );
                GK_User = llDetectedKey( 0 );
                llRegionSay( 2221, "comm|ping" );
                llSetTimerEvent( 5 );
            } else if( GI_Open && GK_User != NULL_KEY ) {
                openDialog();
            } else if( llDetectedKey(0) != GK_User ) {
                llRegionSayTo( llDetectedKey(0), 0, "The "+ llGetObjectDesc() +" Intercomm is in use" );
            }
        } else {
            llRegionSayTo( llDetectedKey(0), 0, "You are far too far away to make use of the "+ llGetObjectDesc() +" Intercomm" );
        }
    }
    
    
    
    timer() {
        llSetTimerEvent( 0 );
        if( !GI_Open && GK_User != NULL_KEY ) {
            openListen( );
            openDialog();
        } else {
            closeListen();
        }
    }



    listen( integer chan, string name, key id, string msg ) {
        if( chan == 2221 ) {
            llRegionSayTo( id, 2222, "comm|pong" );
        } else if( chan == 2222 ) {
            if( msg == "comm|pong" ) {
                string desc = getRootDesc( id );
                if( desc != "" ) {
                    procTerminal( id, desc );
                }
            }
        } else if( chan == 3333 ) {
            llOwnerSay( name +": "+ msg );
            if( getRootName( id ) == llGetObjectName() ) {
                string desc = getRootDesc( id );
                llPlaySound( llList2Key( GL_Sounds, llFloor(llFrand(llGetListLength( GL_Sounds ))) ), 1.0 );
                llSetLinkPrimitiveParamsFast( GI_Speaker, [PRIM_NAME, "The voice of "+ name ] );
                doSay( msg );
            }
        } else if( chan == 9 ) {
            llOwnerSay( msg );
            if( GK_TargetTerm != NULL_KEY ) {
                llSetTimerEvent( 30 );
                llSetLinkPrimitiveParamsFast( GI_Speaker, [PRIM_NAME, name] );
                doBroadcast( msg, GK_TargetTerm );
            }
        } else if( chan == 9999 ) {
            procCmd( msg );
        }
    }
    
    
    
    changed( integer flag ) {
        if( flag & CHANGED_REGION_START ) {
            llResetScript();
        }
    }
}
