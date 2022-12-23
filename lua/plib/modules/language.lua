local RunConsoleCommand = RunConsoleCommand
local hook_Run = hook.Run
local cvars = cvars

module( 'language', package.seeall )

if (CLIENT) then

    local current = cvars.String( 'gmod_language', 'en' )
    cvars.AddChangeCallback('gmod_language', function( _, __, new )
        hook_Run( 'LanguageChanged', current, new )
        current = new
    end, 'PLib - Translate')

    function Get()
        return current
    end

    function Set( languageCode )
        RunConsoleCommand( 'gmod_language', languageCode )
    end

end

if (SERVER) then

    local CreateConVar = CreateConVar
    local table_Empty = table.Empty

    local phrases = {}
    function Add( placeHolder, fullText )
        phrases[ placeHolder ] = fullText
    end

    function GetPhrase( placeHolder )
        return phrases[ placeHolder ] or placeHolder
    end

    local current = CreateConVar( 'sv_language', 'en', FCVAR_ARCHIVE, 'Server side game language.' ):GetString()
    cvars.AddChangeCallback('sv_language', function( _, __, new )
        hook_Run( 'LanguageChanged', current, new )
        table_Empty( phrases )
        current = new
    end, 'PLib - Translate')

    function Get()
        return current
    end

    function Set( languageCode )
        RunConsoleCommand( 'sv_language', languageCode )
    end

end

do

    local plib_Debug = plib.Debug
    local SysTime = SysTime
    local ipairs = ipairs
    local string = string
    local file = file

    function AddFolder( folderPath, gameDir, functions )
        functions = functions or {}
        local files, folders = file.Find( file.Path( folderPath, '*' ), gameDir )
        for _, fl in ipairs( files ) do
            local stopWatch = SysTime()
            local filePath = file.Path( folderPath, fl )
            local fileClass = file.Open( filePath, 'r', gameDir )
            while not fileClass:EndOfFile() do
                local line = fileClass:ReadLine()
                if (line ~= nil) and string.match( line, '%s*#%s*[%w_.]*=' ) == nil then
                    local pos = string.find( line, '=' )
                    if (pos ~= nil) then
                        local fulltext = string.sub( line, pos + 1 )
                        if (fulltext) then
                            Add( string.sub( line, 1, pos - 1), string.Replace( fulltext, '\n', '' ) )
                        end
                    end
                end
            end

            fileClass:Close()
            plib_Debug( 'Phrases from file `{0}` loaded. ({1} seconds)', filePath, string.format( '%.4f', SysTime() - stopWatch ) )
        end

        for _, fol in ipairs( folders ) do
            AddFolder( file.Path( folderPath, fol ), gameDir, functions )
        end
    end

end