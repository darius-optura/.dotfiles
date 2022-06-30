function gbr --description 'List all directories and their active git branch'
  for dir in */
    if test -d "$dir/.git"
      cd $dir && echo "$dir [$(git rev-parse --abbrev-ref HEAD)]"
      cd ..
    else
      cd $dir
      for subdir in */
        if test -d "$subdir/.git"
          cd $subdir && echo "$dir$subdir [$(git rev-parse --abbrev-ref HEAD)]"
          cd ..
        end
      end
      cd ..
    end
  end
end
