local RunConsoleCommand = RunConsoleCommand
local hook_Run = hook.Run
local cvars = cvars

module( 'language', package.seeall )

if (CLIENT) then

    local current = cvars.String( 'gmod_language', 'en' )
    cvars.AddChangeCallback('gmod_language', function( _, __, new )
        hook_Run( 'LanguageChanged', current, new )
        current = new
    end, 'PLib - Language')

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
    end, 'PLib - Language')

    function Get()
        return current
    end

    function Set( languageCode )
        RunConsoleCommand( 'sv_language', languageCode )
    end

end

do

    local plib_Debug = plib.Debug
    local utf8_char = utf8.char
    local tonumber = tonumber
    local ipairs = ipairs
    local string = string
    local file = file

    local function unicodeToChar( str )
        return utf8_char( tonumber( str, 16 ) )
    end

    function AddFolder( folderPath, gameDir )
        local files, folders = file.Find( file.Path( folderPath, '*' ), gameDir )
        for _, fl in ipairs( files ) do
            local filePath = file.Path( folderPath, fl )
            local content = file.Read( filePath, gameDir )
            if (content) then
                for placeholder, str in string.gmatch( content, '([%w_%-]-)=(%C+)' ) do
                    Add( placeholder, string.gsub( str, '\\u(%w%w%w%w)', unicodeToChar ) )
                end
            end

            plib_Debug( 'Phrases from file `{0}` loaded.', filePath )
        end

        for _, fol in ipairs( folders ) do
            AddFolder( file.Path( folderPath, fol ), gameDir )
        end
    end

end