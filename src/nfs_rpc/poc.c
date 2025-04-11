#define FHSIZE3 64

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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



char *fh2str1(fhandle3 fh) {
    unsigned int ndigits = fh.fhandle3_len;
    char *result = malloc(ndigits + 1);
    for (int i = 0; i < ndigits; ++i) {
        sprintf(result+i, "%02x", fh.fhandle3_val[i]);
    }
    result[ndigits] = '\0';
    return result;
}

char *fh2str2(nfs_fh3 fh) {
    unsigned int ndigits = fh.data.data_len;
    char *result = malloc(ndigits + 1);
    for (int i = 0; i < ndigits; ++i) {
        sprintf(result + i, "%02x", fh.data.data_val[i]);
    }
    result[ndigits] = '\0';
    return result;
}


int main(int argc, char **argv) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <server> <share_path> <target_file>\n", argv[0]);
        exit(1);
    }

    char *server = argv[1];
    char *share_path = argv[2];
    char *target_file = argv[3];


    //
    // First we use the MOUNT protocol to get the top level file handle for the share
    //

    CLIENT *mount_clnt = clnt_create(server, MOUNTPROG, MOUNT_V3, "tcp");
    if (!mount_clnt) {
        clnt_pcreateerror("failed to initialize MOUNTv3 client");
        exit(1);
    }

    mount_clnt->cl_auth = authunix_create_default();

    printf("mount_clnt = %p\n", mount_clnt);

    struct mountres3 *res = mountproc3_mnt_3(&share_path, mount_clnt);
    if (!res) {
        clnt_perror(mount_clnt, "failed to MNT");
        exit(1);
    }
    if (res->fhs_status != 0) {
        fprintf(stderr, "mount failed, status %d\n", res->fhs_status);
        clnt_destroy(mount_clnt);
        exit(1);
    }

    struct mountres3_ok resok = res->mountres3_u.mountinfo;
    fhandle3 rootfh = resok.fhandle;
    printf("root fh = %s\n", fh2str1(rootfh));

    struct nfs_fh3 share_fh;
    share_fh.data.data_len = rootfh.fhandle3_len;
    share_fh.data.data_val = rootfh.fhandle3_val;

    clnt_destroy(mount_clnt);




    //
    // Now we can use the NFS protocol to crawl the share
    //

    CLIENT *nfs_clnt = clnt_create(server, NFS_PROGRAM, NFS_V3, "tcp");
    if (!nfs_clnt) {
        clnt_pcreateerror("failed to initialize NFSv3 client");
        exit(1);
    }
    
    printf("nfs_clnt = %p\n", nfs_clnt);

    nfs_clnt->cl_auth = authunix_create_default();


    FSINFO3args fsinfo_args;
    memset(&fsinfo_args, 0, sizeof(fsinfo_args));
    fsinfo_args.fsroot = share_fh;

    FSINFO3res *fsinfo_res = nfsproc3_fsinfo_3(&fsinfo_args, nfs_clnt);
    if (!fsinfo_res) {
        clnt_perror(nfs_clnt, "failed to NFSv3 FSINFO");
        clnt_destroy(nfs_clnt);
        exit(1);
    }
    if (fsinfo_res->status != NFS3_OK) {
        fprintf(stderr, "nfs fsinfo failed with status %d\n", fsinfo_res->status);
        clnt_destroy(nfs_clnt);
        exit(1);
    }



    LOOKUP3args lookup_args;
    memset(&lookup_args, 0, sizeof(lookup_args));
    lookup_args.what.dir = share_fh;
    lookup_args.what.name = target_file;

    LOOKUP3res *lookup_res = nfsproc3_lookup_3(&lookup_args, nfs_clnt);
    if (!lookup_res) {
        clnt_perror(nfs_clnt, "failed to NFSv3 LOOKUP");
        clnt_destroy(nfs_clnt);
        exit(1);
    }
    if (lookup_res->status != NFS3_OK) {
        fprintf(stderr, "nfs lookup failed with status %d\n", lookup_res->status);
        clnt_destroy(nfs_clnt);
        exit(1);
    }

    struct LOOKUP3resok lookup_resok = lookup_res->LOOKUP3res_u.resok;
    nfs_fh3 targ_fh = lookup_resok.object;

    printf("dest fh = %s\n", fh2str2(targ_fh));
    


    clnt_destroy(nfs_clnt);

    return 0;
}

