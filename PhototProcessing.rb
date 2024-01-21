require "exif"
require 'date'
require 'json'
require 'fileutils'


def prepare_file_hash(filepath)
    print filepath
    $stdout.flush
    if !File.file?(filepath)
        puts " FAIL"
        return nil
    end

    h = {}
    h[:path] = filepath
    h[:filename] = File.basename(filepath)
    h[:size] = File.size(filepath)
    exif = nil
    begin
        exif = Exif::Data.new(File.open(filepath))
    rescue
    end
    h[:dst_folder] = "without_exif"
    if exif == nil
        puts " NO_EXIF"
        return h
    end
    sd = exif.date_time
    if sd == nil
        puts " EXIF NO DATE TIME"
        return h
    end
    h[:date_time] = DateTime.strptime(sd, '%Y:%m:%d %H:%M:%S')
    h[:date_time_string] = sd

    h[:dst_folder] = sd[0..9].gsub(":", "_")
    puts " OK"
    return h
end


def enumerate_folder(folderpath, files_hash_array)
    count = 0
    Dir.entries(folderpath).each  { |f|
        if (f != ".") && (f != "..") && (f != ".DS_Store")
            fullpath = File.join(folderpath, f)
            if File.file? fullpath
                h = prepare_file_hash(fullpath)
                if h != nil
                    files_hash_array << h
                    count = count + 1
                end
            end
            if File.directory? fullpath
                count = count + enumerate_folder(fullpath, files_hash_array)
            end
        end
    }
    return count
end


def compare_hash_files_is_equal(h1,h2)
    if h1[:size] != h2[:size]
        return false
    end
    if h1[:date_time_string] != h2[:date_time_string]
        return false
    end
    return FileUtils.compare_file(h1[:path], h2[:path])
end

def compare_files_is_equal(path1,path2)
    if File.size(path1) != File.size(path2)
        return false
    end
    return FileUtils.compare_file(path1, path2)
end


def process_single_filehash(folder, file_hash)
    print " processing "+file_hash[:path]+" ... "
    $stdout.flush
    test_path = File.join(folder, file_hash[:filename])
    if File.exist? test_path
        if compare_files_is_equal(file_hash[:path], test_path)
            # nothing - file is equals
            FileUtils.rm file_hash[:path]
            puts "REMOVE - already exist"
            return
        end
        file_ext = File.extname(test_path)
        file_name = File.basename(test_path, ".*")
        for i in 1..100000 do
            newname =  file_name + "_"+i.to_s+file_ext
            test_path = File.join(folder, newname)
            if File.exist? test_path
                if compare_files_is_equal(file_hash[:path], test_path)
                    # nothing - file is equals
                    FileUtils.rm file_hash[:path]
                    puts "REMOVE - already exist"
                    return
                end
            else
                FileUtils.mv file_hash[:path],test_path
                puts "MOVED with new name ["+newname+"]"
                return
            end

        end
        puts "ERROR"
        return
    else
        FileUtils.mv file_hash[:path],test_path
        puts "MOVED"
        return
    end
end


def prepare_files(files, folders)
    files.each { |x|
        ds = x[:dst_folder]
        f = folders[ds]
        if f == nil
            folders[ds] = []
            f = folders[ds]
        end
        f << x
    }
end


def process_folders(folders, dst_folder, count)
    number = 1
    folders.each {|folder, files|
        dst = File.join(dst_folder, folder)
        if !Dir.exist? dst
            FileUtils.mkdir_p dst
        end
        files.each { |fh|
            #puts "number = "+number.to_s+" count = "+count.to_s
            percent = (number.to_f*100.0)/count.to_f
            percent_str = "#{format("%.2f", percent)}"
            print " [ "+percent_str+"% ] "
            $stdout.flush
            process_single_filehash(dst, fh)
            number = number + 1
        }
    }
end


files_hash_array = []

result_files = {}


src_folder = "/Volumes/SSD_STORAGE/MEDIA/INPUT"
dst_folder = "/Volumes/SSD_STORAGE/MEDIA/OUTPUT"

#src_folder = "/Volumes/SSD_STORAGE/TEST/INPUT"
#dst_folder = "/Volumes/SSD_STORAGE/TEST/OUTPUT"

#src_folder = "/Volumes/SSD_STORAGE/TMP/PHOTOS.NEW.cr"

count = enumerate_folder(src_folder, files_hash_array)

prepare_files(files_hash_array, result_files)


#puts "\nINPUT:\n"
#puts JSON.pretty_generate(files_hash_array)

#puts "\nOUTPUT:\n"
#puts JSON.pretty_generate(result_files)

process_folders(result_files, dst_folder, count)
