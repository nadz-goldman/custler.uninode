#!/usr/bin/env bash

# (C) Sergey Tyurin  2022-02-08 19:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s)
# if this breaks your stuff. This script/function is provided AS IS without warranty of any kind. 
# Author(s) disclaim all implied warranties including, without limitation, 
# any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
# In no event shall author(s) be held liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, 
# loss of business information, or other pecuniary loss) arising out of the use of or inability 
# to use the script or documentation. Neither this script/function, 
# nor any part of it other than those parts that are explicitly copied from others, 
# may be republished without author(s) express written permission. 
# Author(s) retain the right to alter this disclaimer at any time.
##################################################################################################################

################################################################################################
# NB! This update script will work correctly only if RNODE_GIT_COMMIT="master" in env.sh  ! ! !
# In other case, you have to update node manually ! ! !
################################################################################################

echo
echo "#################################### Full update Script ########################################"
echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date  +'%F %T %Z')"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"

exitVar=0

shopt -s nocasematch
if [[ ! -z ${Enable_Node_Autoupdate} || -n ${Enable_Node_Autoupdate} ]]
then
    if [[ ${Enable_Node_Autoupdate} != "true" ]]
    then
        exitVar=1
    else
        myNodeAutoupdate=1
    fi
fi

if [[ ! -z ${Enable_Scripts_Autoupdate} || -n ${Enable_Scripts_Autoupdate} ]]
then
    if [[ ${Enable_Scripts_Autoupdate} != "true" ]]
    then
        exitVar=2
    else
        myScriptsAutoupdate=1
    fi
fi

if [[ ! -z ${newReleaseSndMsg} || -n ${newReleaseSndMsg} ]]
then
    if [[ ${newReleaseSndMsg} != "true" ]]
    then
        exitVar=3
    else
      myNewReleaseSndMsg=1
    fi
fi
shopt -u nocasematch

#===========================================================
# Get scripts update info
Custler_Scripts_local_commit="$(git --git-dir="${SCRIPT_DIR}/../.git" rev-parse HEAD 2>/dev/null)"
Custler_Scripts_remote_commit="$(git --git-dir="${SCRIPT_DIR}/../.git" ls-remote 2>/dev/null | grep 'HEAD'|awk '{print $1}')"

if [[ -z $Custler_Scripts_local_commit ]];then
    echo "###-ERROR(line $LINENO): Cannot get LOCAL Scripts commit!"
    exit 1
fi
if [[ -z $Custler_Scripts_remote_commit ]];then
    echo "###-ERROR(line $LINENO): Cannot get REMOTE Scripts commit!"
    exit 1
fi

###############################################################
#===========================================================
if [[ "$Custler_Scripts_local_commit" != "$Custler_Scripts_remote_commit" ]]
then
    echo '---WARN: Set Enable_Node_Autoupdate to true in env.sh for automatically security updates!! If you fully trust me, you can enable autoupdate scripts in env.sh by set variable "Enable_Scripts_Autoupdate" to "true"'
    if [[ $myNewReleaseSndMsg -eq 1 ]]
    then
        "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_Warn_sign"+'WARN: Security info! **NEW** release arrived! But Enable_Node_Autoupdate setted to false and you should upgrade node manually as fast as you can! If you fully trust me, you can enable autoupdate scripts in env.sh by set variable "Enable_Scripts_Autoupdate" to "true"' 2>&1 > /dev/null
    fi
fi
# Update env.sh for new security update
# ok, here we use force to set autoupdate, strannen'ko =)
# sed -i.bak 's/Enable_Autoupdate=.*/Enable_Node_Autoupdate=true             # will automatically update rnode, rconsole, tonos-cli etc../' "${SCRIPT_DIR}/env.sh"
# sed -i.bak '/Enable_Node_Autoupdate/a Enable_Scripts_Autoupdate=false      # Updating scripts. NB! Change it to true if you fully trust me ONLY!!' "${SCRIPT_DIR}/env.sh"
###############################################################

#===========================================================
# Update scripts, if enabled, or send msg re update
if [[ ${myScriptsAutoupdate} -eq 1 ]]
then
    if [[ "$Custler_Scripts_local_commit" == "$Custler_Scripts_remote_commit" ]];then
        echo "---INFO: Scripts is up to date"
    else
        if $Enable_Scripts_Autoupdate ;then
            echo "---INFO: SCRIPTS going to update from $Custler_Scripts_local_commit to new commit $Custler_Scripts_remote_commit"
            if [[ $myNewReleaseSndMsg -eq 1 ]]; then
                "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_Warn_sign INFO: SCRIPTS going to update from $Custler_Scripts_local_commit to new commit $Custler_Scripts_remote_commit" 2>&1 > /dev/null
            fi
            Remote_Repo_URL="$(git remote show origin | grep 'Fetch URL' | awk '{print $3}')"
            echo "---INFO: Update scripts from repo $Remote_Repo_URL"

            #=======================================
            mkdir -p ${HOME}/Custler_tmp
            cp -f ${SCRIPT_DIR}/env.sh ${HOME}/Custler_tmp/
            cp -f ${SCRIPT_DIR}/TlgChat.json ${HOME}/Custler_tmp/
            cp -f ${SCRIPT_DIR}/RC_Addr_list.json ${HOME}/Custler_tmp/

            git reset --hard
            git pull --ff-only

            cp -f  ${HOME}/Custler_tmp/env.sh ${SCRIPT_DIR}/
            cp -f  ${HOME}/Custler_tmp/TlgChat.json ${SCRIPT_DIR}/
            cp -f  ${HOME}/Custler_tmp/RC_Addr_list.json ${SCRIPT_DIR}/
            #=======================================

            cat ${SCRIPT_DIR}/Update_Info.txt
            echo
            echo "---INFO: SCRIPTS updated. Files env.sh TlgChat.json RC_Addr_list.json keeped."
            if [[ $myNewReleaseSndMsg -eq 1 ]]; then
                "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_CheckMark $(cat ${SCRIPT_DIR}/Update_Info.txt)" 2>&1 > /dev/null
                "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_CheckMark INFO: SCRIPTS updated. Files env.sh TlgChat.json RC_Addr_list.json keeped." 2>&1 > /dev/null
            fi
        else
            echo '---WARN: Scripts repo was updated. Please check it and update by hand. If you fully trust me, you can enable autoupdate scripts in env.sh by set variable "Enable_Scripts_Autoupdate" to "true"'
            if [[ $myNewReleaseSndMsg -eq 1 ]]; then
                "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "$Tg_Warn_sign"+'WARN: Scripts repo was updated. Please check it and update. If you fully trust me, you can enable autoupdate scripts in env.sh by set variable "Enable_Scripts_Autoupdate" to "true"' 2>&1 > /dev/null
            fi
        fi
    fi
fi
#===========================================================
# Update NODE
${SCRIPT_DIR}/Update_Node_to_new_release.sh

echo "+++INFO: $(basename "$0") FINISHED $(date +%s) / $(date  +'%F %T %Z')"
echo "================================================================================================"

exit 0
