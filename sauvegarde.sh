#!/bin/bash
LOG_FILE=/home/tcomputer/Documents/backup_`date '+%d-%m-%y_%HH%M'`.log 
touch LOG_FILE;
# Script de sauvegarde (complète et incrémentale)
# Réalisé le 20/04/2020 par TAME Florian
# Requiert les paquets 'tree' et 'mail'
# Réalise au moins une save 
        #echo -e "\nLa sauvegarde retourne un code erreur : $RESULT\n" && cat $LOG_FILE | /usr/bin/mail $MAIL_TO -s "Problème Backup de $BACKUP_DIR KO" --complète avant les incrémentales
# Vérifie les dépendances et existences de modifications
# Notifie l'utilisateur sur l'état des backups
   
# Variables ajustables :
BACKUP_DIR=/home/tcomputer/Bureau/test              # L'espace à sauvagarder
BACKUP_STOCK=/home/tcomputer/Documents/SAUVEGARDES              # Le stockage des backups
LOG_DIR=/home/tcomputer/Documents/SAUVEGARDES 
TTL=4                                               # Time to live d'un backup
TTR=7                                               # Time to rotate (full - $TTR - full)
DATE=`date '+%d-%m-%y_%HH%M'`                       # Date à insérer dans le nom
#LOG_FILE=/home/tcomputer/Documents/backup_`date '+%d-%m-%y_%HH%M'`.log   # Le fichier de log
MAIL_FROM=FlorianKamguia@gmail.com                  # Le mail envoyeur
NAME_FROM=backup                                    # Le nom de destinataire
MAIL_TO=florian.tame@facsciences-uy1.cm             # Le mail du destinataire
FILE_NAME=/home/tcomputer/./sauvegarde.sh
REMOTE_SERVER=192.168.122.1
login=tcomputer


#receuillir les privilèges de super utilisateur 
print_help(){
        HELP_STRING='
Instructions for backuping and restoring your system data:

First of all a word of warning: If you do not know what you 
are doing, you can easily erase all your data and seriously 
fuck-up your system by mistake! You can do so even when you know 
what you are doing, by being careless.

First, make sure to have all the required dependances to run 
this script eg. tree, mail, ... if not the program will mention it
and you will be oblige to install it if you want to continue.

This script can be use for automating some tasks likes:

        - Backup a particular folder localy and even to a remote server
        - choose the backup method than you want.
        - Restore data localy and even from a remote server


It is important to mention that a FULL BACKUP is firstly recommended.
As you can see each task is preceded by a number so to execute it, 
you will just enter the corresponding number.

you should firstly setup the path of the file or the folder to backup 
and by the same occasion the path of the folder where the backup will 
be store (in case of local backup ) 

after that, for remote backup it will be very important to set 
the address of the remote server by defining his ip_addr or domaine name and his port 

I hope that this has been somewhat helpful.

If there is a bug or some errors occurs during the exploration 
just mention it at this address https://githup.com/Tcomputer5/sauvegarde.git
'
        echo "${HELP_STRING}" | more
}
become_su()
{
if [[ "$EUID" -ne 0 ]] 
	then 
	echo "We need root (administrator) privileges to run this..." 
	sudo bash -c "${0}" echo "" read -p "Press [enter] to terminate. " asomevar 
	exit 0
	fi
}

time_of_backup(){
        END=$(date +%s)
        DIFF=$(($END - $START))
        printf "Cette opération a durée: %02d:%02d:%02d (hours:minutes:seconds)" $(($DIFF/3600)) $(($DIFF/3600/60)) $(($DIFF%60)) >>$LOG_FILE
        echo " "
}
#inserer un commentaire dans le fichier des logs

set_mail(){
        read -p 'Entrez votre @mail' mail ;
        $mail>>MAIL_TO

}
select_dir(){
        echo 'Entrez le ou les';
}

definecron() 
{
        if [[ $(crontab -u tcomputer -l | egrep -v '^(#|$)' | grep -q 'eval /home/tcomputer/Bureau/sauvegarde.sh'; echo $?) == 1 ]]
        then
                set -f 
                printf "$(crontab -u tcomputer -l; echo "${min} ${hour} ${d_month} ${month} ${d_week} eval /home/tcomputer/Bureau/sauvegarde.sh")\n" | crontab -
                set +f
        else
                printf "la tache a déjà été ajouté ";
        fi
        #echo "$min $hour $d_month $month $d_week $FILE_NAME ">> /etc/crontab;
        #echo "$min $hour $d_month $d_week";
        
}
reponse(){
         if [["$?" == "0"]]
                 then
                echo "opération terminée avec succès";
         else
                echo "une erreur c'est produite bien vouloir jettez un coup d'oeil";
         fi
}
# Fonction de backup complet
save_full ()
{

NBRE_FILES=`find $BACKUP_DIR -type f 2>/dev/null | wc -l`
if [[ $NBRE_FILES == 0 ]]
        then
        echo -e "Il n'y a aucun fichier dans $BACKUP_DIR, donc INUTILE DE SAUVEGARDER" >> $LOG_FILE
        RESULT=0
        #notif
        else
                read -p "Quelle sauvegarde voulez vous faire Locale ou à distance [L] ou [D]: " decision
                case $decision in 
                [lL]|[lL][oO][cC][aA][lL][eE])
                        echo -e "\nSAUVEGARDE COMPLETE" 
                        echo -e "\nSAUVEGARDE COMPLETE" >> $LOG_FILE
                        tar -czvg snapshot-file -f $BACKUP_STOCK/SAVE_FULL_$DATE.tgz $BACKUP_DIR 2>/dev/null
                        # h permet d'afficher les infos sous un format lisible à l'homme
                        # a fait appel au mode d'archivage
                        # v operations parlantes
                        #rsync -avhz  $BACKUP_DIR $BACKUP_STOCK 

                        echo -n "arborescence du repertoire contenant la sauvegarde"
                        tree -L 1 $BACKUP_STOCK
                        RESULT=$?
                        sleep 3
                        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
                        echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
                        ;;
                [dD]|[dD][iI][sS][tT][aA][nN][tT])
                        echo -e "\nSAUVEGARDE COMPLETE" 
                        echo -e "\nSAUVEGARDE COMPLETE" >> $LOG_FILE
                        #tar -czf $BACKUP_STOCK/SAVE_FULL_$DATE.tgz $BACKUP_DIR 2>/dev/null
                        # h permet d'afficher les infos sous un format lisible à l'homme
                        # a fait appel au mode d'archivage
                        # v operations parlantes

                        tar -czvg snapshot-file -f $BACKUP_STOCK/SAVE_FULL_$DATE.tgz $BACKUP_DIR 2>/dev/null
                        LISTE=`ls -tr $BACKUP_STOCK | grep SAVE_FULL`
                        for x in $LISTE;
                        do
                        rsync -e ssh -avh $x $login@$REMOTE_SERVER:/home/tcomputer/Documents/SAUVEGARDES 
                        done
                        

                        echo -n "arborescence du repertoire contenant la sauvegarde"
                        tree -L 1 $BACKUP_STOCK
                        RESULT=$?
                        sleep 3
                        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
                        echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
        
                        ;;
                *)
                        echo -e "Choix non valide donc je choisi locale"
                        echo -e "\nSAUVEGARDE COMPLETE" 
                        echo -e "\nSAUVEGARDE COMPLETE" >> $LOG_FILE
                        #tar -czf $BACKUP_STOCK/SAVE_FULL_$DATE.tgz $BACKUP_DIR 2>/dev/null
                        # h permet d'afficher les infos sous un format lisible à l'homme
                        # a fait appel au mode d'archivage
                        # v operations parlantes
                        #rsync -avhz  $BACKUP_DIR $BACKUP_STOCK 

                        echo -n "arborescence du repertoire contenant la sauvegarde"
                        tree -L 1 $BACKUP_STOCK #`find $BACKUP_DIR -type f -mtime -1` #2>/dev/null # -1*24 représente le nombre d'heure' avant lequel un fichier peut être considéré comme updateACKUP_STOCK
                        RESULT=$?
                        sleep 3
                        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
                        echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
                        ;;
                esac
               fi
}

 
# Fonction de backup incrémental
save_inc ()
{
echo -e "\nSAUVEGARDE INCREMENTALE"
echo -e "\nSAUVEGARDE INCREMENTALE" >> $LOG_FILE
NBRE_FILES=`find $BACKUP_DIR  2>/dev/null | wc -l`

if [[ $NBRE_FILES == 0 ]]
        then
	echo -e "Il n'y a aucun fichier dans $BACKUP_DIR, donc INUTILE DE SAUVEGARDER"
        echo -e "Il n'y a aucun fichier dans $BACKUP_DIR, donc INUTILE DE SAUVEGARDER" >> $LOG_FILE
        RESULT=0
        #notif
        else
                read -p "Quelle sauvegarde voulez vous faire Locale ou à distance [L] ou [D]: " decision
                case $decision in 
                [lL]|[lL][oO][cC][aA][lL][eE])
                        tar -czvg snapshot-file -f  $BACKUP_STOCK/SAVE_INC_$DATE.tgz $BACKUP_DIR

                        ;;
                [dD]|[dD][iI][sS][tT][aA][nN][tT])
                        tar -czvg snapshot-file -f  $BACKUP_STOCK/SAVE_INC_$DATE.tgz $BACKUP_DIR

                        FILE=`ls -t $BACKUP_STOCK | grep SAVE_INC | head -1 `
                        rsync -e ssh -avh $FILE $login@$REMOTE_SERVER:/home/tcomputer/Documents/SAUVEGARDES 
                        ;;
                *)
                        echo -e "Choix non valide donc je choisi locale"
                
        esac
                        sleep 3
                        RESULT=$?
                        
                        echo -e "\nArborescence de l'espace de backup\n" >> $LOG_FILE && tree -L 1 $BACKUP_STOCK >> $LOG_FILE
                        echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
                        
        
fi
}

# Fonction de backup de différentielle 

save_diff()
{
echo -e "\nSAUVEGARDE DIFFERENTIELLE "
echo -e "\nSAUVEGARDE DIFFERENTIELLE " >> $LOG_FILE
NBRE_FILES=`find $BACKUP_DIR -type f  2>/dev/null | wc -l`
if [[ $NBRE_FILES == 0 ]]
        then
        echo -e "\nIl n'y a pas eut de modifications dans le repertoire , donc INUTILE DE SAUVEGARDER\n" >> $LOG_FILE
        RESULT=0
        #notif
        exit 0
        else
        #LISTE=`ls -t $BACKUP_STOCK | grep SAVE_FULL | head -1 `
        #tar --diff -czf $BACKUP_STOCK/SAVE_DIFF_$DATE.tgz  2>/dev/null
        #rsync --archive -h
        
        echo -e "\nArborescence de l'espace backupé\n" >> $LOG_FILE && tree -L 1 $BACKUP_DIR >> $LOG_FILE
        echo -e "\nTaille de l'espace disque des backup\n" >> $LOG_FILE && du -hs $BACKUP_STOCK/* >> $LOG_FILE
        fi
}

restauration(){
         read -p "Quelle Restauration voulez vous faire Locale ou à distance [L] ou [D]" decision
                case $decision in 
                [lL]|[lL][oO][cC][aA][lL][eE])
                        LISTE=`ls -tr $BACKUP_STOCK | grep SAVE`
                        for x in $LISTE;
                        do
                        tar -xvf $BACKUP_STOCK/$x -C /home/tcomputer/Documents/RESTAURATION
                        done
                        #rsync --delete -avh $BACKUP_STOCK $BACKUP_DIR
                        #tar -xvf /root/practicelab/backup.tar.gz -C /root/practicelab/restore
                        ;;
                [dD]|[dD][iI][sS][tT][aA][nN][tT])
                        rsync -e ssh -avh $login@$REMOTE_SERVER:/home/tcomputer/Documents/SAUVEGARDES/* $BACKUP_STOCK 
                        ;;
                *)
                        echo -e "Choix non valide "
                        ;;
                esac
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
 
# Fonction de verification de dépendances
check_dependance ()
{
# Est ce que TREE est installé
if [[ `/usr/bin/which tree | wc -l` == 0  ]];
        then
        RESULT=1
        echo -e "Le paquet TREE doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS"
        echo -e "Le paquet TREE doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        #notif
else
        echo "OK"
fi

# Est ce que MAIL est installé
#if [[ `/usr/bin/which mail | wc -l`  == 0 ]];
#        then
#        RESULT=1
#        echo -e "Le paquet MAIL doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS"
#        echo -e "Le paquet MAIL doit être installé !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
#        #notif
#else
#        echo "OK"
#fi

        #echo -e "\nLa sauvegarde retourne un code erreur : $RESULT\n" && cat $LOG_FILE | /usr/bin/mail $MAIL_TO -s "Problème Backup de $BACKUP_DIR KO" --
# Est ce que l'espace de stockage des backups existe
if [[ -d $BACKUP_STOCK ]];
        then
        echo "OK"
        else
        RESULT=1
        echo -e "Le répertoire de stockage ($BACKUP_STOCK) n'existe pas !\n JE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        #notif
fi
# Est ce que l'espace à backuper existe
if [[ -d $BACKUP_DIR ]];
        then
        echo OK > /dev/null
        else
        RESULT=1
        echo -e "Le répertoire à sauvegarder ($BACKUP_DIR) n'existe pas !\n JE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        #notif
        fi


# Est ce que l'espace disque est inférieur à 95%
if [[ `df -h $BACKUP_STOCK | tail -1 | awk {'print $5'} | sed "s/.$//"` -ge 80 ]];
        then
        RESULT=1
        echo "L'espace disque de la partition contenant $BACKUP_STOCK est supérieur ou égal à 95% !\nJE REFUSE DE CONTINUER DANS CES CONDITIONS" >> $LOG_FILE
        #notif
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

limit_log(){
CALCUL_TTL=`expr $TTL - 1`
LISTE=`ls -t $LOG_FILE | grep backup | sed -e "1,"$CALCUL_TTL"d"`

for x in $LISTE;
do
        rm -f $LOG_DIR/$x
        echo -e "\nSuppression de $x en fontion de votre limite de $TTL logs" >> $LOG_FILE
done
} 
set_repository(){
        read -p "Entrez le chemin absolu du repertoire à sauvegarder: " REPO
        if [-d $REPO];
        then
                $BACKUP_DIR=$REPO
                echo $BACKUP_DIR
        else
                 echo -e "Le répertoire à sauvegarder ($REPO) n'existe pas !\n JE REFUSE DE CONTINUER DANS CES CONDITIONS"
        fi
}

# Script de backup
#become_su

echo -e "> Backup du `date +%D` à `date +%H:%M:%S`\n";
echo -e "> Backup du `date +%D` à `date +%H:%M:%S`\n" > $LOG_FILE
#check_dependance
limit_backup
# Test au moins 1 complete avant le choix du type de sauvegarde
       

#clear;
become_su;
stop="true";
while $stop != "true" 
do

	echo "=====================================================================================";
	echo "|                                                                                   |";
	echo "|         BIENVENU SUR VOTRE PROGRAMME DE SAUVEGARDES SUR DES SYSTEMES LINUX        |";
	echo "|                                                                                   |";
	echo "=====================================================================================";
	echo "|                             QUE VOULEZ VOUS FAIRE ?                               |";
	echo "|____________________________-----------------------________________________________|";
	echo "|                                                                                   |";
	echo "| 1- Verifier les dépendances             2- definir votre adresse mail(facultatif) |";
	echo "| 3- selectionner le(s) repertoire(s) pour la sauvegarde (source)                   |";
	echo "|                                                                                   |";        
        echo "|__________________Quel type de sauvegarde voulez vous exécuter?____________________|";      
 	echo "|                      ________________________________________                     |";   
        echo "| 4- Laisser le sytème décider (une sauvegarde complète est primordiale)            |"; 
	echo "| 5- Sauvegarde complète                            6- Sauvegarde incrémentale      |";
	echo "| 7- Sauvegarde différentielle                      8- Restauration                 |";
	echo "| 9- Définir la frequence d'exécution du script                                     |";
	echo "| 10- Aide                                          11- Quitter                     |";
	echo " =================================================================================== ";
    
	echo "";
	read -p 'Que voulez vous faire ? ' option ;

	case $option in 

		1)
			check_dependance
			;;
		2)
			set_mail
			;;
		3)
			set_repository
			;;
		4)
                        check_dependance
			START=$(date +%s);
			 NBRE_FULL=`ls $BACKUP_STOCK/SAVE_FULL_* 2>/dev/null | wc -l`;
                                if [[ $NBRE_FULL > 0 ]];
                                        then
                                                # Calcul la date de la derniere full et si < 3 alors on sauvegarde en incrementale
                                                NBRE_INC=`ls -lt $BACKUP_STOCK | grep SAVE | head -$TTR | grep INC | wc -l`
                                        if [[ "$NBRE_INC" -lt "$TTR" ]];
                                                then
                                                save_inc
                                        
                                                #notif
                                        else
                                                save _full
                                        
                                                #notif
                                        fi
                                else
                                save_full
                                #notif
                                #limit_backup
                                limit_log 
                                fi
                        echo "Opération terminée avec succès !!!"
                        limit_backup
                        limit_log       
                        time_of_backup
                        sleep 3
			;;
		5)
                        check_dependance
                        START=$(date +%s)
			save_full
                        limit_log
                        limit_backup
                        time_of_backup
                        echo "Opération terminée avec succès"
                        sleep 3
			;;
		6)
                        check_dependance
                        START=$(date +%s);
			 NBRE_FULL=`ls $BACKUP_STOCK/SAVE_FULL_* 2>/dev/null | wc -l`;
                                if [[ $NBRE_FULL > 0 ]];
                                        then
                                        # Calcul la date de la derniere full et si < 3 alors on sauvegarde en incrementale
                                        NBRE_INC=`ls -lt $BACKUP_STOCK | grep SAVE | head -$TTR | grep INC | wc -l`
                                        if [[ "$NBRE_INC" -lt "$TTR" ]];
                                                then
                                                save_inc
                                                
                                                #notif
                                        else
                                                save _full
                                                
                                                #notif
                                        fi
                                else
                                save_full
                                #notif
                                fi
                        limit_backup 
                        limit_log      
                        time_of_backup
                        sleep 3
			;;
		7)
                        check_dependance
                        START=$(date +%s);
			 NBRE_FULL=`ls $BACKUP_STOCK/SAVE_FULL_* 2>/dev/null | wc -l`;
                                if [[ $NBRE_FULL > 0 ]];
                                        then
                                        # Calcul la date de la derniere full et si < 3 alors on sauvegarde en incrementale
                                        NBRE_INC=`ls -lt $BACKUP_STOCK | grep SAVE | head -$TTR | grep DIFF | wc -l`
                                        if [[ "$NBRE_INC" -lt "$TTR" ]];
                                                then
                                                save_diff
                                                
                                                #notif
                                        else
                                                save _full
                                                
                                                #notif
                                        fi
                                else
                                save_full
                                #notif
                                fi
                        #limit_backup 
                        limit_log      
                        time_of_backup
                        sleep 3
			;;
		8)
			restauration
			;;
		9)
			read -p "Veuillez renseigner les champs commme suis MM (minutes): " min; 
                        read -p " HH (heures): " hour;
                        read -p " DOM (jour(s) du mois ): " d_month;
                        read -p " M( mois): " month;
                        read -p " DOW (jour de la semaine): " d_week; 
                        echo "${min} ${hour} ${d_month} ${month} ${d_week}";
                        definecron;
                        reponse
			;;


		10)
			print_help
			;;
		11)
                        echo "Aurevoir Et à Bientôt ...";
			sleep 2;
			echo "";
			exit 0
			;;
		*)
		echo "commande introuvable "
		;;

	esac

	echo "";
	read -p "Voulez vous continuer ? [O/N] :" response
		case "$response" in
		    [yY][eE][sS]|[yY]|[oO]|[oO][uU][iI]) 
			clear;
			continue
			;;
		    [nN]|[nN][oO])
			stop="false";
			echo "Aurevoir Et à Bientôt ...";
			sleep 2;
			echo "";
			exit 1
			;;
		    *)
			clear;
			continue
			;;
		esac

done

