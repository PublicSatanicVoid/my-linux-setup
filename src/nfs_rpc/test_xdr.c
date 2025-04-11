#define FHSIZE3 64

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

#include <rpc/rpc.h>
#include <rpc/clnt.h>
#include <rpc/svc.h>
#include <rpc/xdr.h>
#include <rpc/clnt_stat.h>
#include <rpc/types.h>

struct timeval TIMEOUT = { 25, 0 };
#include <nfs23.h>
#include <mount.h>
#include <mount_clnt.c>
#include <mount_xdr.c>
#include <nfs23_clnt.c>
#include <nfs23_xdr.c>



char *fh2str(nfs_fh3 fh) {
    unsigned int ndigits = fh.data.data_len;
    char *result = malloc(ndigits + 1);
    for (int i = 0; i < ndigits; ++i) {
        sprintf(result + i, "%02x", fh.data.data_val[i]);
    }
    result[ndigits] = '\0';
    return result;
}


/**
 * Creates a client to `server` and finds the root file handle of `volume` on
 * that server. The MOUNT protocol is handled internally to the caller; all returned
 * objects are in the NFS protocol.
 */
int mount_nfs3(char *server, char *volume, CLIENT **clnt, nfs_fh3 *rootfh) {
    CLIENT *mount_clnt = clnt_create(server, MOUNTPROG, MOUNT_V3, "tcp");
    if (!mount_clnt) {
        clnt_pcreateerror("Failed to initialize MOUNT v3 client");
        return 1;
    }

    mount_clnt->cl_auth = authunix_create_default();

    //printf("mount_clnt = %p\n", mount_clnt);

    struct mountres3 *res = mountproc3_mnt_3(&volume, mount_clnt);
    if (!res) {
        clnt_perror(mount_clnt, "Failed to execute MNT procedure");
        return 1;
    }
    if (res->fhs_status != 0) {
        fprintf(stderr, "MNT procedure returned error status %d\n", res->fhs_status);
        clnt_destroy(mount_clnt);
        return 1;
    }

    struct mountres3_ok resok = res->mountres3_u.mountinfo;
    fhandle3 handle = resok.fhandle;

    rootfh->data.data_len = handle.fhandle3_len;
    rootfh->data.data_val = handle.fhandle3_val;

    clnt_destroy(mount_clnt);
    
    *clnt = clnt_create(server, NFS_PROGRAM, NFS_V3, "tcp");
    if (!*clnt) {
        clnt_pcreateerror("Failed to initialize NFS v3 client");
        return 1;
    }
    
    //printf("nfs_clnt = %p\n", *clnt);

    (*clnt)->cl_auth = authunix_create_default();

    return 0;
}


int resolve_relpath(CLIENT *clnt, nfs_fh3 start_fh, char *relpath, nfs_fh3 *out_fh) {
    // Resolve each part of the target path to get the target file handle
    
    char relpath_copy[PATH_MAX + 1];
    relpath_copy[0] = '\0';
    strncpy(relpath_copy, relpath, PATH_MAX);
    relpath_copy[PATH_MAX] = '\0';

    //printf("Resolving target path to fh...\n");
    nfs_fh3 tree_fh = start_fh;
    char *part = strtok(relpath_copy, "/");
    while (part) {
        LOOKUP3args lookup_args;
        memset(&lookup_args, 0, sizeof(lookup_args));
        lookup_args.what.dir = tree_fh;
        lookup_args.what.name = part;

        LOOKUP3res *lookup_res = nfsproc3_lookup_3(&lookup_args, clnt);
        if (!lookup_res) {
            clnt_perror(clnt, "Failed to execute LOOKUP procedure");
            return 1;
        }
        if (lookup_res->status != NFS3_OK) {
            fprintf(stderr,
                    "LOOKUP procedure returned error status %d\n",
                    lookup_res->status);
            return 1;
        }

        struct LOOKUP3resok lookup_resok = lookup_res->LOOKUP3res_u.resok;
        nfs_fh3 targ_fh = lookup_resok.object;

        //printf("* %s --> %s\n", part, fh2str(targ_fh));

        tree_fh = targ_fh;
        part = strtok(NULL, "/");
    }

    out_fh->data.data_len = tree_fh.data.data_len;
    out_fh->data.data_val = tree_fh.data.data_val;

    return 0;
}


int getattr_nfs3(CLIENT *clnt, nfs_fh3 fh, fattr3 *result) {
    GETATTR3args args;
    memset(&args, 0, sizeof(args));
    args.object = fh;

    GETATTR3res *res = nfsproc3_getattr_3(&args, clnt);
    if (!res) {
        clnt_perror(clnt, "Failed to execute GETATTR procedure");
        return 1;
    }
    if (res->status != NFS3_OK) {
        fprintf(stderr, "GETATTR procedure returned error status %d\n", res->status);
        return 1;
    }

    struct GETATTR3resok resok = res->GETATTR3res_u.resok;
    memcpy(result, &resok.obj_attributes, sizeof(resok.obj_attributes));
    return 0;
}


int calc_tree_size(CLIENT *clnt, nfs_fh3 fh, size_t *size_bytes, size_t *nr_items) {

    // Not implemented yet

    return 0;
}


int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <server> <volume> <relpath>\n", argv[0]);
        exit(1);
    }

    char *server = argv[1];
    char *volume = argv[2];
    char *relpath = argv[3];


    nfs_fh3 share_fh;
    CLIENT *nfs_clnt;
    if (mount_nfs3(server, volume, &nfs_clnt, &share_fh) != 0) {
        fprintf(stderr, "Failed to mount %s:%s; exiting\n", server, volume);
        exit(1);
    }


    nfs_fh3 tree_fh;
    if (resolve_relpath(nfs_clnt, share_fh, relpath, &tree_fh) != 0) {
        fprintf(stderr, "Failed to resolve %s; exiting\n", relpath);
        clnt_destroy(nfs_clnt);
        exit(1);
    }

    //printf("dest fh = %s\n", fh2str(tree_fh));


    ////////Testing XDR fragments
    int nconn = 1;
    for (int i = 0; i < nconn; ++i) {
        int clfd = socket(AF_INET, SOCK_STREAM, 0);
        struct sockaddr_in server_addr = {
            .sin_family = AF_INET,
            .sin_port = htons(2049),
            .sin_addr.s_addr = inet_addr(server)
        };
        if (connect(clfd, (struct sockaddr*) &server_addr, sizeof(server_addr)) < 0) {
            printf("Couldn't connect to server (#%d)\n", i);
            exit(1);
        }
        printf("Connected to the server (#%d)\n", i);
    }

    //TODO: 'Manually' send and receive NULL RPC using TCP socket directly

    //TODO: 'Manually' send and receive LOOKUP RPC using TCP socket directly

    //TODO: 'Manually' send and receive READDIRPLUS RPC using TCP socket directly




    ////////Testing RPC parallelism
    
    //TODO: Send 2 NULL RPCs before waiting for response

    //TODO: Send 2 READDIRPLUS RPCs before waiting for response

    //TODO: Abstract sending a READDIRPLUS into a function, as well as waiting for a
    //response from any of the in-progress calls



    ////////Commenting out until we're ready for the actual 'du' part.
    ////fattr3 tree_top_attr;
    ////if (getattr_nfs3(nfs_clnt, tree_fh, &tree_top_attr) != 0) {
    ////    fprintf(stderr, "Failed to get attributes of %s; exiting\n", relpath);
    ////    clnt_destroy(nfs_clnt);
    ////    exit(1);
    ////}


    ////size_t size_bytes = tree_top_attr.size;
    ////size_t nr_items = 0;
    ////if (calc_tree_size(nfs_clnt, tree_fh, &size_bytes, &nr_items) != 0) {
    ////    fprintf(stderr, "Failed to calculate disk usage of %s; exiting\n", relpath);
    ////    clnt_destroy(nfs_clnt);
    ////    exit(1);
    ////}


    ////printf("Size (bytes): %lu\n", size_bytes);
    ////printf("Total items:  %lu\n", nr_items);


    clnt_destroy(nfs_clnt);

    return 0;
}

