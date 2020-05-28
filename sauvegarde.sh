#!/bin/bash
# Script de sauvegarde (complète et incrémentale)
# Réalisé le 20/04/2020
# Requiert les paquets 'tree' et 'mail'
# Réalise au moins une save complète avant les incrémentales
# Vérifie les dépendances et existences de modifications
# Notifie l'utilisateur sur l'état des backups
   
# Variables ajustables :
BACKUP_DIR=/home/tcomputer/Bureau/test              # L'espace à sauvagarder
BACKUP_STOCK=/home/tcomputer/Documents              # Le stockage des backups
TTL=1                                               # Time to live d'un backup
TTR=1                                               # Time to rotate (full - $TTR - full)
DATE=`date '+%d-%m-%y_%HH%M'`                       # Date à insérer dans le nom
LOG_FILE=/tmp/backup_`date '+%d-%m-%y_%HH%M'`.log   # Le fichier de log
MAIL_FROM=FlorianKamguia@gmail.com                  # Le mail envoyeur
NAME_FROM=backup                                    # Le nom de destinataire
MAIL_TO=florian.tame@facsciences-uy1.cm             # Le mail du destinataire
 
# Fonction de backup complet
save_full ()
{
echo -e "\nSAUVEGARDE COMPLETE" >> $LOG_FILE
NBRE_FILES=`find $BACKUP_DIR -type f 2>/dev/null | wc -l`
if [[ $NBRE_FILES == 0 ]]
        then
        echo -e "\nIl n'y a aucun fichier dans $BACKUP_DIR, donc INUTILE DE SAUVEGARDER\n" >> $LOG_FILE
        RESULT=0
        notif
        exit 0
        else
        tar -czf $BACKUP_STOCK/SAVE_FULL_$DATE.tgz $BACKUP_DIR 2>/dev/null
        RESULT=$?
        sleep 3
        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
        sudo echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
        fi
}

 
# Fonction de backup incrémental
save_inc ()
{
echo -e "\nSAUVEGARDE INCREMENTALE" >> $LOG_FILE
NBRE_FILES=`find $BACKUP_DIR -type f -mtime -1 2>/dev/null | wc -l`
if [[ $NBRE_FILES == 0 ]]
        then
        echo -e "\nIl n'y a pas eut de modifications dans les dernières 24 heures, donc INUTILE DE SAUVEGARDER\n" >> $LOG_FILE
        RESULT=0
        notif
        exit 0
        else
        tar -czf $BACKUP_STOCK/SAVE_INC_$DATE.tgz `find $BACKUP_DIR -type f -mtime -1` 2>/dev/null
        sleep 3
        RESULT=$?
        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
        sudo echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
        fi
}



# Fonction de notification
notif ()
{
if [[ $RESULT == 0 ]];
        then
        cat $LOG_FILE | /usr/bin/mail $MAIL_TO -s "Backup de $BACKUP_DIR OK" -- -f $MAIL_FROM -F $NAME_FROM
        rm -f $LOG_FILE
        else
        echo -e "\nLa sauvegarde retourne un code erreur : $RESULT\n" && cat $LOG_FILE | /usr/bin/mail $MAIL_TO -s "Problème Backup de $BACKUP_DIR KO" -- -f $MAIL_FROM -F $NAME_FROM
        rm -f $LOG_FILE
        fi
}
 
# Fonction de check
check_dependance ()
{
# Est ce que TREE est installé
if [[ `/usr/bin/which tree | wc -l` == 0  ]];
        then
        RESULT=1
        echo -e "Le paquet TREE doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        notif
        exit 1
        fi
# Est ce que MAIL est installé
if [[ `/usr/bin/which mail | wc -l`  == 0 ]];
        then
        RESULT=1
        echo -e "Le paquet MAIL doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        notif
        exit 1
        fi
# Est ce que l'espace de stockage des backups existe
if [[ -d $BACKUP_STOCK ]];
        then
        echo OK > /dev/null
        else
        RESULT=1
        echo -e "Le répertoire de stockage ($BACKUP_STOCK) n'existe pas !\n JE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        notif
        exit 1
        fi
# Est ce que l'espace à backuper existe
if [[ -d $BACKUP_DIR ]];
        then
        echo OK > /dev/null
        else
        RESULT=1
        echo -e "Le répertoire à sauvegarder ($BACKUP_DIR) n'existe pas !\n JE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        notif
        exit 1
        fi


# Est ce que l'espace disque est inférieur à 95%
if [[ `df -h $BACKUP_STOCK | tail -1 | awk {'print $5'} | sed "s/.$//"` -ge 95 ]];
        then
        RESULT=1
        echo "L'espace disque de la partition contenant $BACKUP_STOCK est supérieur ou égal à 95% !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        notif
        exit 1
        fi
}
 
# Fonction de limite du nombre de backups
limit_backup ()
{
CALCUL_TTL=`expr $TTL - 1`
LISTE=`ls -t $BACKUP_STOCK | grep SAVE | sed -e "1,"$CALCUL_TTL"d"`
for x in $LISTE;
        do
        rm -f $BACKUP_STOCK/$x
        echo -e "\nSuppression de $x en fontion de votre limite de $TTL backups" >> $LOG_FILE
        done
}
 

# Script de backup
echo -e "> Backup du `date +%D` à `date +%H:%M:%S`\n" > $LOG_FILE
check_dependance
limit_backup
# Test au moins 1 complete avant le choix du type de sauvegarde
        NBRE_FULL=`ls $BACKUP_STOCK/SAVE_FULL_* 2>/dev/null | wc -l`
        if [[ $NBRE_FULL > 0 ]];
                then
                # Calcul la date de la derniere full et si <3 alors on sauvegarde en incrementale
                NBRE_INC=`ls -lt $BACKUP_STOCK | grep SAVE | head -$TTR | grep INC | wc -l`
                if [[ "$NBRE_INC" -lt "$TTR" ]];
                then
                save_inc
                notif
                else
                save_full
                notif
                fi
        else
        save_full
        notif
        fi
#exit 0