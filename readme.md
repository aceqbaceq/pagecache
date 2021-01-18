--

pagecache 
изначально это делалось для того чтобы если у нас на диске есть миллионы файлов
и мы хотим удалить все файлы старше такой то даты то удаление их через rm 
зайнимает кучу времени. пришла идея сделат через откат и снэпшоты.
выяснилось что снэпшоты неподходят. они позволяются откатиться назад 
тоесть как бы отрубить новые ростки на дереве а нужно наоборот отрубить корни.

тогда пришла идея сделаь это через слои overlayFS.

есть у нас локальная папка которая смонтирована через overlayFS.
в нем есть lower и upper слой. все изменения пишутся в upper слой. 
получается что если upper слой сделать lower слоем
а lower слой отформатировать и сделать upper слоем то мы можем получить
такую штуку что у нас в merged слое будут оставаться только файлы 
записанные младше такой то даты а файлы старше такой то даты
исчезли.

--

echo "# pagecache" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/aceqbaceq/pagecache.git
git push -u origin main


--

в папке main-files лежат все необхдоимые файлы чтобы все заработало
    в main-files\samba лежат файлы чтобы расшарить оверлей через самбу
    в main-files\nfs лежат файлы чтобы расшарить оверлей через  nfs
в папке different-hlam лежат разные файлы которые были использованы при подоготовке проекта

--

pagecache_switch_snapshots.sh - это самый главный файл он переключает снэпшоты
pagecache_start_after_reboot.sh - этот скрипт монтирует оверлей раздел после перезарузки компа и запускает самбу
pagecache-start.service - это systemd служба которая срабатывает при старте компа и вызывает pagecache_start_after_reboot.sh
pagecache_freespace_check.sh - это скрипт который надо поместить в cron и он проверяет сколько осталось свободного места на разделе
    и если ниже порогового то вызывает  pagecache_switch_snapshots.sh который переключает снэпшот
smb.conf - конф файл самбы до кучи так как ради нее все и выстраивается
--

в crontab надо вставить строчку

* * * * * /usr/local/bin/pagecache_freespace_check.sh >/dev/null 2>&1

скрипт будет запускаться каждую минуту

--

nfs
особенности работы через nfs.
когда мы хотим расшарить оверлей через nfs то по дефолту это не получится сделать.
при попытке экспортнуть выдаст ошибку
    exportfs: /data/merged does not support NFS export
так вот чтобы этого небыло надо монтировать оверлей с особыми опциями:
    index=on,redirect_dir=nofollow,nfs_export=on
полная версия:
# mount -t overlay /mnt/overlay1/merged -o rw,noatime,redirect_dir=nofollow,index=on,nfs_export=onlowerdir=/mnt/overlay1/lower,upperdir=/mnt/overlay1/upper/upper,workdir=/mnt/overlay1/upper/workdir

--

сравнение перфоманса шары на NFS (линукс сервер) и виндовс шары (эталонный виндовс сервер)
и сравнение нагрузки на цпу при этом 

тест идет на чтении\записи мелких файлов, 
в один поток

read
(windows машина samba )	 1.4MB\s , загрузка cpu 40% (1 ядро)
(linux машина NFS )	 2.8MB\s , загрузка cpu 7-10% (1 ядро)

write
(windows машина samba )	 1.3MB\s , загрузка cpu ?? 
(linux машина NFS)	 1.8Mb\s , загрузка cpu 15% (1 ядро)

вывод: как видно линукс nfs рулит и по скорости и по нагрузке на цпу по сравнению с виндовс самбой сервером.

еще важная инфо: в отличии от линукс nfs сервера линуксовский smb сервер вообще некатит , он жрет очень много цпу.поэтому его нереально использовать
под нагрузкой из мелких файлов

что еще интересно - эксперимент показал что многопоточная нагрузка невлияет на загрузку цпу NFS сервера 
что один поток что несколько вроде как пофиг.
--

