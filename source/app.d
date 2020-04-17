import std.stdio;
import std.string : fromStringz;
import std.conv;

import bindbc.sdl;
import bindbc.sdl.image;
//import bindbc.sdl.bind.sdlvideo;

import bindbc.opengl;

void main()
{
    // Load SDL libs
    const SDLSupport ret = loadSDL();
    if(ret != sdlSupport) {
      writeln("Error loading SDL dll");
      return;
    }
    if(loadSDLImage() != sdlImageSupport) {
      writeln("Error loading SDL Image dll");
      return;
    }

    // Initialise SDL
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }
    scope(exit) {
      SDL_Quit();
    }

    // Initialise IMG
    const flags = IMG_INIT_PNG | IMG_INIT_JPG;
    if ((IMG_Init(flags) & flags) != flags) {
        writeln("IMG_Init: ", to!string(IMG_GetError()));
    }
    scope(exit) {
      IMG_Quit();
    }

    version(OSX) {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG); // Always required on Mac
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    } else {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    }
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

    // Create a window
    const windowFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_SHOWN;
    SDL_Window* appWin = SDL_CreateWindow(
        "Example #2",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        windowFlags
    );
    if (appWin is null) {
        writefln("SDL_CreateWindow: ", SDL_GetError());
        return;
    }
    scope(exit) {
        // Close and destroy the window
        if (appWin !is null) {
            SDL_DestroyWindow(appWin);
        }
    }
    // Load image
    SDL_Surface* imgSurf = IMG_Load("grumpy-cat.jpg");
    if (imgSurf is null) {
        writeln("IMG_Load: ", to!string(IMG_GetError()));
    }
    scope(exit) {
        // Close and destroy the surface
        if (imgSurf !is null) {
            SDL_FreeSurface(imgSurf);
        }
    }

    SDL_GLContext gContext = SDL_GL_CreateContext(appWin);
    if (gContext == null) {
      writeln("OpenGL context couldn't be created! SDL Error: ", fromStringz(SDL_GetError()));
      return;
    }
    scope(exit) {
        if (gContext !is null) {
            SDL_GL_DeleteContext(gContext);
        }
    }

    const GLSupport openglLoaded = loadOpenGL();
    if ( openglLoaded != glSupport) {
      writeln("Error loading OpenGL shared library", to!string(openglLoaded));
      return;
    }
    SDL_GL_MakeCurrent(appWin, gContext);

    SDL_GL_SetSwapInterval(1); // Enable VSync

    // Creating a texture from SDL Surface
    glEnable(GL_TEXTURE_2D);
    GLuint textureID = 0;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    const mode = imgSurf.format.BytesPerPixel == 4 ? GL_RGBA : GL_RGB;
    glTexImage2D(GL_TEXTURE_2D, 0, mode, imgSurf.w, imgSurf.h, 0, mode, GL_UNSIGNED_BYTE, imgSurf.pixels);
    scope(exit) {
      glDeleteTextures(1, &textureID);
    }

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glBindTexture(GL_TEXTURE_2D, 0);

    // Initializin matrices
    GLenum error = GL_NO_ERROR;

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //Initialize Projection Matrix
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();

    //Check for error
    error = glGetError();
    if( error != GL_NO_ERROR ) {
      return;
    }

    //Initialize Modelview Matrix
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    //Check for error
    error = glGetError();
    if( error != GL_NO_ERROR ) {
      return;
    }

    //Initialize clear color
    glClearColor( 0f, 0f, 0f, 1f );

    //Check for error
    error = glGetError();
    if( error != GL_NO_ERROR ) {
      return;
    }

    glFlush();
    SDL_GL_SwapWindow(appWin);

    // Polling for events
    bool quit = false;
    while(!quit) {
        SDL_PumpEvents();

        // Cleaning buffers
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glClearColor( 0f, 0f, 0f, 1f );

        // Render something
        glBindTexture(GL_TEXTURE_2D, textureID);
        glBegin( GL_QUADS );
          glColor3f(1.0f, 1.0f, 1.0f);
          glTexCoord2f(0f, 0f);
          glVertex2f( -0.5f, -0.5f );

          glColor3f(1.0f, 0.0f, 0.0f);
          glTexCoord2f(1f, 0f);
          glVertex2f( 0.5f, -0.5f );

          glColor3f(0.0f, 1.0f, 0.0f);
          glTexCoord2f(1f, 1f);
          glVertex2f( 0.5f, 0.5f );

          glColor3f(0.0f, 0.0f, 1.0f);
          glTexCoord2f(0f, 1f);
          glVertex2f( -0.5f, 0.5f );
        glEnd();


        //Update screen
        glFlush();
        SDL_GL_SwapWindow(appWin);

        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                quit = true;
            }

            if (event.type == SDL_KEYDOWN) {
                quit = true;
            }
        }
    }

}
